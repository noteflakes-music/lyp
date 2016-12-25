- Specs for CLI commands.

- Specs for lilypond command.

- rename require, pinclude, pincludeOnce etc:

```lilypond
\req "blah"
\incl "blah.ly"
\inclOnce "blah.ly"
\condIncl #(eq? edition 'urtext) "urtext_tweaks.ly"
\condInclOnce #(eq? edition 'urtext) "urtext_tweaks.ly"
```

