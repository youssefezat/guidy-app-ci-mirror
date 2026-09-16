"""
Render Guidy's policy documents into public/ for Firebase Hosting.

WHY THIS EXISTS
---------------
Meta, Google Play and AdMob all require a privacy policy at a stable
public URL, and Meta additionally requires a data-deletion page it can
fetch during App Review. Both documents already existed in this repo --
they were just sitting in a private repository, which is not a URL.

The markdown files stay the source of truth and the HTML is generated,
because the alternative is copies of a legal document drifting apart --
now in two languages, which doubles the ways that goes wrong. This repo
has already been bitten by hand-editing generated files twice
(lib/l10n/app_localizations*.dart), so: edit the markdown, re-run this,
redeploy.

    python3 build_site.py && firebase deploy --only hosting

A note on caching, since firebase.json cannot carry comments: hosting
there sets Cache-Control: no-cache on everything. Firebase's default is
max-age=3600, which meant a corrected policy took up to an hour to reach
anyone who had already opened the page -- and they had no way to know
they were reading a stale version of a legal document. "no-cache" does
not mean "do not cache"; it means revalidate first, so unchanged pages
still come back as a 304. The two logo PNGs re-validating is a rounding
error next to publishing a policy that quietly lies for an hour.

The app is bilingual, so the policy is too. The Arabic is Modern
Standard Arabic rather than the Egyptian colloquial the UI speaks: this
is a legal document, and that is the register readers expect for one.
The English text is authoritative and each Arabic page says so.

The leading HTML comment in each source file is editorial -- notes to
whoever maintains the document -- and is stripped rather than published.
"""

import io
import os
import re
import shutil
import sys

try:
    import markdown
except ImportError:
    sys.exit(
        "build_site.py needs the 'markdown' package:\n"
        "    pip install markdown==3.10.3\n"
        "Pinned because the generated HTML is committed and CI diffs it -- a\n"
        "different version can render the same markdown slightly differently\n"
        "and fail the check for no real reason."
    )

OUT = "public"
CONTACT = "guidygroup@gmail.com"
BASE = "https://guidy-19e46.web.app"

# (source, output, <title>, lang, path of this page, path of its translation)
PAGES = [
    ("PRIVACY_POLICY.md",     "privacy.html",          "Privacy Policy",
     "en", "/privacy",         "/privacy-ar"),
    ("PRIVACY_POLICY.ar.md",  "privacy-ar.html",       "سياسة الخصوصية",
     "ar", "/privacy-ar",      "/privacy"),
    ("TERMS_AND_CONDITIONS.md",    "terms.html",    "Terms and Conditions",
     "en", "/terms",           "/terms-ar"),
    ("TERMS_AND_CONDITIONS.ar.md", "terms-ar.html", "الشروط والأحكام",
     "ar", "/terms-ar",        "/terms"),
    ("DATA_DELETION.md",      "data-deletion.html",    "Data Deletion",
     "en", "/data-deletion",   "/data-deletion-ar"),
    ("DATA_DELETION.ar.md",   "data-deletion-ar.html", "تعليمات حذف البيانات",
     "ar", "/data-deletion-ar", "/data-deletion"),
]

# No "dir" key here on purpose: direction is derived from lang at the one
# place it is used. A second copy of it in this table would be a value
# that can silently disagree with the one that matters.
STRINGS = {
    "en": {"other": "العربية", "questions": "Questions",
           "privacy": "Privacy", "terms": "Terms", "deletion": "Data deletion"},
    "ar": {"other": "English", "questions": "للاستفسار",
           "privacy": "سياسة الخصوصية", "terms": "الشروط والأحكام",
           "deletion": "حذف البيانات"},
}

# Logical properties throughout (padding-inline-start, not padding-left)
# so the same stylesheet lays out correctly under dir="rtl" without a
# second set of rules to keep in sync.
# Palette mirrors AppColors in lib/theme/app_theme.dart -- test_build_site.py
# reads that file and fails if the two drift apart. The dark theme is the
# app's obsidian slate (#0F1722 / #182230), not the old navy wash (#0B3D71
# cards) the app deliberately moved away from.
#
# --g1..--g5 are AppColors.brandGradient, in order, for the top strip.
#
# --blue and --amber are decorative only (brand strip, markers, borders):
# brandBlue is 2.8:1 on white and brandAmberDark 2.6:1, both below WCAG AA
# for text. Text roles (--link, --heading, --accent-ink) use shades from the
# app's own gradients that clear 4.5:1 on --card in each mode.
def _font_faces():
    """@font-face rules for the self-hosted copies in site_assets/fonts/.

    Self-hosted rather than linked from fonts.googleapis.com: a privacy
    policy page should not hand every reader's IP address to a third party
    before it renders, and a render-blocking cross-origin stylesheet leaves
    the page blank on a slow or filtered connection. Both families are
    SIL OFL 1.1 (licence texts are published next to the files).
    unicode-range lets the browser fetch only the subsets a page uses."""
    arabic = "U+0600-06FF, U+0750-077F, U+0870-088E, U+0890-0891, U+0897-08E1, U+08E3-08FF, U+200C-200E, U+2010-2011, U+204F, U+2E41, U+FB50-FDFF, U+FE70-FE74, U+FE76-FEFC"
    latin = "U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD"
    rules = []
    for weight in (400, 700, 800):
        for subset, rng in (("arabic", arabic), ("latin", latin)):
            rules.append(
                '@font-face{font-family:"Almarai";font-style:normal;'
                'font-weight:%d;font-display:swap;'
                'src:url(/fonts/almarai-%s-%d.woff2) format("woff2");'
                'unicode-range:%s}' % (weight, subset, weight, rng))
    # Nunito Sans is a variable font: one file covers 400-800.
    rules.append(
        '@font-face{font-family:"Nunito Sans";font-style:normal;'
        'font-weight:400 800;font-display:swap;'
        'src:url(/fonts/nunito-sans-latin.woff2) format("woff2");'
        'unicode-range:%s}' % latin)
    return "\n".join(rules)


CSS = _font_faces() + """
:root{
  --navy:#0b3d71; --blue:#2da3e3; --amber:#e88916;
  --bg:#f8fafc; --card:#ffffff; --ink:#0b1b2b; --muted:#64748b;
  --rule:#e2e8f0;
  --g1:#0b3d71; --g2:#14548e; --g3:#1c75b0; --g4:#dc973c; --g5:#ffbc70;
  --heading:#0b3d71; --link:#1c75b0; --accent-ink:#14548e;
}
@media (prefers-color-scheme:dark){
  :root{ --amber:#ffbc70;
         --bg:#0f1722; --card:#182230; --ink:#ffffff; --muted:#94a3b8;
         --rule:#223042;
         --heading:#ffffff; --link:#2da3e3; --accent-ink:#ffbc70; }
}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--ink);
  font:16px/1.65 "Nunito Sans",-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif}
body[dir="rtl"]{
  font-family:"Almarai","Segoe UI","Noto Sans Arabic",Tahoma,
    -apple-system,BlinkMacSystemFont,Arial,sans-serif;
  line-height:1.9;
}
/* The app's brandGradient (navy -> blue -> amber), as a thin top strip. */
.brand-strip{height:4px;background:linear-gradient(90deg,
  var(--g1) 0%,var(--g2) 28%,var(--g3) 58%,var(--g4) 80%,var(--g5) 100%)}
body[dir="rtl"] .brand-strip{background:linear-gradient(270deg,
  var(--g1) 0%,var(--g2) 28%,var(--g3) 58%,var(--g4) 80%,var(--g5) 100%)}
.bar{max-width:760px;margin:0 auto;padding:24px 20px 0;
  display:flex;align-items:center;justify-content:space-between;gap:16px}
/* Both logos were showing at once. `.bar img` is (0,1,1) and
   `.logo-dark` was (0,1,0), so the sizing rule's display:block beat the
   hiding rule and neither logo could ever be hidden. It worked before
   only because the selector used to be `header img` (0,0,2), which a
   bare class outranks. Sizing and visibility are now separate concerns
   at matching specificity. */
.bar img{height:34px;width:auto}
.bar .logo-light{display:block}
.bar .logo-dark{display:none}
@media (prefers-color-scheme:dark){
  .bar .logo-light{display:none}
  .bar .logo-dark{display:block}
}
.lang{color:var(--link);text-decoration:none;font-size:.9rem;font-weight:700;
  background:var(--card);border:1px solid var(--rule);border-radius:999px;
  padding:6px 14px;white-space:nowrap}
.lang:hover{border-color:var(--blue)}
main{max-width:760px;margin:0 auto;padding:20px}
article{background:var(--card);border:1px solid var(--rule);
  border-radius:16px;padding:28px 26px 32px;
  box-shadow:0 1px 2px rgba(11,27,43,.04),0 8px 24px rgba(11,27,43,.05)}
@media (prefers-color-scheme:dark){ article{box-shadow:none} }
h1{font-size:1.6rem;line-height:1.3;margin:.2em 0 .1em;color:var(--heading);
  font-weight:800}
h2{font-size:1.12rem;margin:1.9em 0 .5em;padding-top:.9em;
  border-top:1px solid var(--rule);color:var(--accent-ink);font-weight:700}
h2::before{content:"";display:inline-block;width:4px;height:.95em;
  margin-inline-end:.5em;vertical-align:-.1em;border-radius:2px;
  background:var(--amber)}
h2:first-of-type{border-top:0;padding-top:0}
a{color:var(--link);text-underline-offset:2px}
ul,ol{padding-inline-start:1.25em;padding-left:0}
li{margin:.35em 0}
/* Markers are text (the numbered deletion steps), so --link, not --blue. */
li::marker{color:var(--link)}
hr{border:0;border-top:1px solid var(--rule);margin:2em 0 1.2em}
em{color:var(--muted);font-style:normal;font-size:.9rem}
.meta{color:var(--muted);font-size:.86rem;margin:.2em 0 1.6em}
footer{max-width:760px;margin:0 auto;padding:4px 20px 48px;
  color:var(--muted);font-size:.86rem}
footer a{color:var(--muted)}
footer a:hover{color:var(--link)}
@media (max-width:520px){
  article{padding:22px 18px 26px;border-radius:14px}
  h1{font-size:1.32rem}
}
"""

SHELL = """<!doctype html>
<html lang="{lang}" dir="{dir}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} — Guidy</title>
<meta name="description" content="{title} — Guidy, public transport for Greater Cairo.">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#f8fafc" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#0f1722" media="(prefers-color-scheme: dark)">
<link rel="canonical" href="{base}{self_path}">
{alternates}
<style>{css}</style>
</head>
<body dir="{dir}">
<div class="brand-strip"></div>
<div class="bar">
  <a href="{home}"><img class="logo-light" src="/logo_light.png" alt="Guidy"><img class="logo-dark" src="/logo_dark.png" alt="Guidy"></a>
  <a class="lang" href="{other_path}" hreflang="{other_lang}">{other_label}</a>
</div>
<main><article>
{body}
</article></main>
<footer>{footer}</footer>
</body>
</html>
"""


def render(md_path):
    """Markdown body, minus the editorial comment block at the top."""
    with io.open(md_path, encoding="utf-8") as f:
        text = f.read()
    text = re.sub(r"^\s*<!--.*?-->\s*", "", text, count=1, flags=re.S)
    assert "<!--" not in text, "%s: an editorial comment survived the strip" % md_path
    assert "TODO" not in text, "%s still contains a TODO -- not publishable" % md_path
    return markdown.markdown(text, extensions=["extra", "sane_lists"])


def page(out, title, body, lang, self_path, other_path):
    other_lang = "ar" if lang == "en" else "en"
    alt = "\n".join(
        '<link rel="alternate" hreflang="%s" href="%s%s">' % (l, BASE, p)
        for l, p in ((lang, self_path), (other_lang, other_path))
    )
    s = STRINGS[lang]
    foot = ('{q}: <a href="mailto:{c}">{c}</a> &nbsp;·&nbsp; '
            '<a href="{pv}">{pl}</a> &nbsp;·&nbsp; '
            '<a href="{tm}">{tl}</a> &nbsp;·&nbsp; '
            '<a href="{dl}">{dlabel}</a>').format(
        q=s["questions"], c=CONTACT,
        pv="/privacy" if lang == "en" else "/privacy-ar", pl=s["privacy"],
        tm="/terms" if lang == "en" else "/terms-ar", tl=s["terms"],
        dl="/data-deletion" if lang == "en" else "/data-deletion-ar",
        dlabel=s["deletion"])

    html = SHELL.format(
        lang=lang, dir="rtl" if lang == "ar" else "ltr", title=title, css=CSS,
        base=BASE, self_path=self_path, alternates=alt, body=body, footer=foot,
        home="/" if lang == "en" else "/ar",
        other_path=other_path, other_lang=other_lang,
        other_label=STRINGS[lang]["other"])
    with io.open(os.path.join(OUT, out), "w", encoding="utf-8", newline="\n") as f:
        f.write(html)
    return len(html)


INDEX_EN = """<h1>Guidy</h1>
<p class="meta">Public transport routing for Greater Cairo — metro, monorail,
light rail, bus and microbus.</p>
<p>This site hosts Guidy's policy documents. The app itself is distributed
through the app stores.</p>
<ul>
  <li><a href="/privacy">Privacy Policy</a></li>
  <li><a href="/terms">Terms and Conditions</a></li>
  <li><a href="/data-deletion">Data Deletion Instructions</a></li>
</ul>
"""

INDEX_AR = """<h1>Guidy</h1>
<p class="meta">تخطيط الرحلات بوسائل النقل العام في القاهرة الكبرى — المترو
والمونوريل والقطار الخفيف والحافلات والميكروباص.</p>
<p>يستضيف هذا الموقع المستندات القانونية لتطبيق Guidy. أمّا التطبيق نفسه
فيُوزَّع عبر متاجر التطبيقات.</p>
<ul>
  <li><a href="/privacy-ar">سياسة الخصوصية</a></li>
  <li><a href="/terms-ar">الشروط والأحكام</a></li>
  <li><a href="/data-deletion-ar">تعليمات حذف البيانات</a></li>
</ul>
"""


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)
    for src in ("assets/images/logo_light.png", "assets/images/logo_dark.png"):
        shutil.copy2(src, os.path.join(OUT, os.path.basename(src)))
    # Self-hosted brand fonts + their OFL licence texts (see _font_faces).
    shutil.copytree(os.path.join("site_assets", "fonts"), os.path.join(OUT, "fonts"))

    for out, body, lang, self_p, other_p in (
            ("index.html", INDEX_EN, "en", "/", "/ar"),
            ("ar.html", INDEX_AR, "ar", "/ar", "/")):
        n = page(out, "Guidy", body, lang, self_p, other_p)
        print("  %-24s %6d bytes  [%s]" % (out, n, lang))
    for src, out, title, lang, self_path, other_path in PAGES:
        n = page(out, title, render(src), lang, self_path, other_path)
        print("  %-24s %6d bytes  [%s]  <- %s" % (out, n, lang, src))
    print("built %s/" % OUT)


if __name__ == "__main__":
    main()
