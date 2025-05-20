> Pages URL: https://su-mecanique.github.io/master-mecanique/

# Manual update workflow for pages

1. Go to the [fiches-ue update
   workflow](https://github.com/su-mecanique/fiches-ue-master-mecanique/actions/workflows/manual.yml)
   and click the "Run workflow" button. This will download and commit all
   changes from DropSU.
2. A pull-request should have been automatically created if the workflow
   committed an update. Go to [Pull
   Requests](https://github.com/su-mecanique/master-mecanique/pulls) for
   master-mecanique, check that all jobs succeeded for the new pull request
   (this means that the page generation will work once merged) and merge the
   pull request.
3. Now the pages should be generated, check that the output is correct with the
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
cd ue-list-website
hugo --forceSyncStatic -D server
```
