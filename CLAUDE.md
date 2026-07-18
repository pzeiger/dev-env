# dev-env

Devcontainer definition and provisioning for the local development environment
(ROCm/Ubuntu image, Python venv, and the editable science repos under
`/workspaces/code`).

## Available toolchains

The container ships a full TeX Live 2023 distribution (`latexmk`,
`pdflatex`, `lualatex`, incl. `physics`/`booktabs`) — theory documents can
and should be validated by actual compilation. No flake8/ruff in the venv.

## Git workflow

This is a single-maintainer configuration repo. Commit changes **directly to
`main`** — do not create a topic branch first. Pushing still requires explicit
confirmation from the user.
