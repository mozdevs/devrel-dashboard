# DevRel Dashboard

Will eventually show nice stats and summaries and such about Mozilla DevRel activity across Bugzilla, GitHub, and more.

Work in progress at https://mozdevs.github.io/devrel-dashboard/

## Hacking

1. `npm install`
2. `npm start`
3. http://localhost:8080/

## Contributing

Submit pull requests to the `master` branch.

To update GitHub Pages, make sure your `master` branch is up to date, then:

1. `git checkout gh-pages`
2. `git merge --no-commit master`
3. `npm run build`
4. `git add dist/`
5. `git commit`
6. `git push`
