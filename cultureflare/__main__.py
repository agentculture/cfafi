"""Allow ``python -m cultureflare`` to invoke the CLI."""

from cultureflare.cli import main

if __name__ == "__main__":
    raise SystemExit(main())
