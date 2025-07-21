> Pages URL: https://su-mecanique.github.io/master-mecanique/

# Manual update workflow for pages

1. Go to the [fiches-ue update
   workflow](https://github.com/su-mecanique/fiches-ue-master-mecanique/actions/workflows/manual.yml)
   and click the "Run workflow" button. This will download and commit all
   changes from DropSU. **OR** make a commit and push with the updated sheets.
3. Execute [this
   workflow](https://github.com/su-mecanique/master-mecanique/actions/workflows/update-fiches-ue.yml),
   which will immediately update the `fiches-ue` submodule and should run the
   website generation.
4. Execute [this workflow](https://github.com/su-mecanique/master-mecanique/actions/workflows/run_script.yml).
5. Now the pages should be generated, check that the output is correct with the
   URL above.

# Offline setup

Make sure you have [Hugo](https://gohugo.io/) installed and all submodules up-to-date:

```
git submodule update --init --recursive
```

Set up your virtual environment:

```
python3 -m venv .venv --prompt master-mecanique
source .venv/bin/activate
pip install -r requirements.txt
```

Then build the website:

```
make
```

If you want to have a web-server that automatically updates:

```
make serve
```
