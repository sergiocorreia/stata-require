## Sanity checks we could enforce

- No orphan files
- Two packages cannot point to the same file (e.g. inflate by mistake points to the same files as freduse)
- Note that sometimes (e.g. ivreg2_p.ado) two packages (ivreg2, ivreg29) point to the same valid file, to save space.