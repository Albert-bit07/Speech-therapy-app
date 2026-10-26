# Recognition fixture

`goforward.raw` is the unmodified PocketSphinx test recording from commit
`511126b492dcb267cf30d49d631946d7b61a9530` (v5.1.1):
https://github.com/cmusphinx/pocketsphinx/blob/511126b492dcb267cf30d49d631946d7b61a9530/test/data/goforward.raw

It contains mono signed little-endian 16-bit PCM at 16000 Hz. The transcript is
“go forward ten meters”. SHA-256:
`f15c60ec54059d8b66e410d0064945a0b0a04ea56e1ddca1958e493c0cf70e71`.
Upstream redistribution terms are preserved in `POCKETSPHINX_LICENSE`.

This one upstream fixture checks native model loading, recognition, alignment
and CLI serialization. It is not a held-out accuracy dataset, a child-speech
evaluation, or evidence that the system assesses pronunciation correctly.
