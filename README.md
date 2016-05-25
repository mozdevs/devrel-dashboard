# DevRel Dashboard

Will eventually show nice stats and summaries and such about Mozilla DevRel activity across Bugzilla, GitHub, and more.

Work in progress at https://mozdevs.github.io/devrel-dashboard/

## Hacking

1. `npm install`
2. `npm start`
3. http://localhost:8080/

## Contributing

Submit pull requests to the `master` branch.

To update GitHub Pages:

```
export REMOTE="origin"

git checkout master &&
git pull --ff-only $REMOTE master &&
git checkout gh-pages &&
git pull --ff-only $REMOTE gh-pages &&
git merge --no-commit master &&
npm install &&
npm run build &&
git add dist &&
git commit &&
git push $REMOTE gh-pages:gh-pages &&
git checkout master
```
