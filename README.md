# Macrostrat web components

Web-Components is a [React](https://reactjs.org/) based user interface ecosystem designed for
efficiently developing data-dense web-frontends. Foundationally built upon other UI-Libraries, heavily
upon [@blueprintjs](https://github.com/palantir/blueprint), the components herein are meant to be easily implemented with much of the business logic encapsulated within the library itself.

## Architecture

#### Libraries

Web-Components is a monorepo that holds several libraries in the `/packages` directory. All of the libraries with this directory are constantly being updated and added to. However, stable versions of them can be found on the NPM registry:

- [`@macrostrat/ui-components`](https://www.npmjs.com/package/@macrostrat/ui-components)
- [`@macrostrat/form-components`](https://www.npmjs.com/package/@macrostrat/form-components)
- [`@macrostrat/data-components`](https://www.npmjs.com/package/@macrostrat/data-components)
- [`@macrostrat/column-components`](https://www.npmjs.com/package/@macrostrat/column-components)

#### Apps

Web-Components also holds a collection of web-applications that use the component libraries discussed above. These apps can be found in the `/apps` directory.

## Storybook

The libraries within Web-Components use [Storybook](https://storybook.js.org/) for development and collaboration. There is one main storybook at the root of the monorepo and each library has individual `stories` that are gathered at storybook runtime.

Building the storybook: `yarn run build:storybook`

## For Developers

To get started developing web-components, clone this repository to your machine and run:

```
git submodule init --recursive
```

This will automatically initialize all git submodules used in the monorepo.

Next install all necessary modules. The repository is set up to use **Yarn v2** by default, for
quick installs and updates.

```
yarn
```

To build and view the story book you can run:

```
yarn run dev:storybook --port 3000
```

The storybook will start at port `3000`

If you want to test the feedback component, and want to get data from the database then setup the express server using:
```
cd example_fetcher_server
node ./index.js
```