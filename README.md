# TMathRenderer

TeX math rendering for Delphi. The `TMathRenderer` class converts a formula, such as

```I = \int \rho R^{2} dV``` 

into an image: 

![image](https://github.com/TextEditorPro/TMathRenderer/blob/main/Assetts/formula.png)

Requires Delphi 13, as the code utilizes `if` statements and inline variables.

The parser and layout logic have been ported from the [KaTeX](https://katex.org) library, and KaTeX fonts are used for rendering. Consequently, the output appears identical to how it looks in KaTeX within a web browser.

The original KaTeX fonts contain virtually no "hinting" data; as a result, GDI is unable to align lines to whole pixels or correctly render thin horizontal lines. This issue was resolved using the [ttfautohint](https://freetype.org/ttfautohint) tool.

`TMathRenderer` is not thread-safe; use one instance per thread.

## Job offers

https://www.linkedin.com/in/lassemarkusrautiainen/

## Donations

https://ko-fi.com/texteditorpro