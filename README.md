Mandible: Brainswap’s web application build and development toolset + project template


                              _,.-------.,_
                           ;~'             '~;,
                        ,;                     ;,
                       ;                         ;
                      ,'                         ',
                     ,;                           ;,
                     ; ;      .           .      ; ;
                     | ;   ______       ______   ; |
                     |  `/~"     ~" . "~     "~\'  |
                     |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
                      |   |        }:{        |   |
                      |   l       / | \       !   |
                      .~  (__,.--" .^. "--.,__)  ~.
                      |    ----;' / | \ `;----    |
                       \__.       \/^\/       .__/
                 ___   V| \                 / |V
                |       | |T~\___!___!___/~T| |
                |       | |`IIII_I_I_I_IIII'| |
    Mandible  --|       |  \,III I I I III,/  |
                |        \   `~~~~~~~~~~'    /
                |          \   .       .   /     -dcau (4/15/95)
                |__          \.    ^    ./
                               ^~~~^~~~^

# Sample project!
- There is now an open-source, sample Responsive Backbone Application built using Mandible2. Check it out at [http://dontbreak.me/](http://dontbreak.me/). Complete source code [https://github.com/BrainSwap/dontbreakme](https://github.com/BrainSwap/dontbreakme).

# Change Log
5/12/2012 - Integrated major, backwards compatible updates to the Jake system from the last project we launched which includes:

- Cleaner, enhanced Jakefile with custom variables at the top.
- Production, QA, and Staging deployment endpoint support.
- [Amazon S3](http://aws.amazon.com/s3/) asset uploading with gzip, cache-control, versioning, and cache breaking support. 


# Welcome

Mandible2 is a text editor agnostic HTML5/CSS3/Javascript web application development toolset + project template developed by [Brainswap](http://www.brainswap.com/) while working for client’s like [SocialGenius](http://www.socialgeni.us/) and [Skype](http://www.skype.com/intl/en-us/home), it is now maintained here. Utilizing an ecosystem of well-supported libraries and technologies Mandible provides structure, consistency, and a framework of standardized solutions to development pitfalls and web technology issues when dealing with developing and deploying javascript heavy web apps and mobile friendly web sites.

# Mandible includes

* a cross-browser normalized HTML5 and CSS3 ready project base utilizing [HTML5 boilerplate](http://html5boilerplate.com/) which includes [Modernizr’s](http://http//www.modernizr.com/) conditional [HTML5 polyfill](https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-browser-Polyfills) loader and the [Respond.js](https://github.com/scottjehl/Respond) polyfill for CSS3 Media Query support in older browsers among other gems.
the [Skeleton](http://getskeleton.com/) CSS development kit including a version of the 960 grid system and a set of optimized CSS3 Media Query based style sheets that best target device sizes and orientations for a [responsive](http://www.alistapart.com/articles/responsive-web-design/) design.
the [Sass](http://sass-lang.com/) CSS3 extension which adds nested rules, variables, mixins, selector inheritance for faster, more efficient CSS coding on the development side while translating into well-formatted, standard CSS on the deployment side.

* a standardized source, debug deployment, and production deployment project structure including a customizable [Node.js](http://nodejs.org/) watch and deployment [Jakefile](http://howtonode.org/intro-to-jake) that automatically concatenates and minifies your CSS and JS files for production builds. We recommend using [https://github.com/](Git) for code version control and include a .gitignore in the root project folder so debug and production deployment folders are never checked in.

* the most popular and robust Javascript libraries for application architecture ([Backbone.js](http://documentcloud.github.com/backbone/)), view templating ([Underscore](http://documentcloud.github.com/underscore/#template)), and day-to-day coding ([jQuery](http://jquery.com/))

#Requirements

To use this tools you need to have the following installed:

* You need to install Ruby (already installed on all macs).
* You need to install [Sass](http://sass-lang.com/). `sudo gem install sass`
* You need to install [Node](http://nodejs.org/). (One click-installer for every OS now.)
* You need to install [Jake](http://howtonode.org/intro-to-jake).

# To use

1. Install the above requirements, then in terminal, run the Jakefile watch script by typing `jake` in the project folder. Keep this process running while you work.

2. View your project by browsing to the `deploy-debug` folder. If you're running a web server set document root to `deploy-debug`.

3. Edit the html template under src. Any CSS or JS additions should be added to their respective folders under src and added to the index.html file between the `@css concat start@` and `@css concat end@` markers for CSS and `@javascript concat start@` and `@javascript concat end@` for javascript that should be auto concatenated. New templates added to the src/templates folder will automatically be added to the generated index.html file in the deployment folders.

4. While working, view your changes via refreshing the generated index.html file in the `/deploy-debug/` debug deployment folder in your web browser.

5. When you want to generate a production ready version of the deployment folder, in a new Terminal tab type `jake build-prod`. Run `jake clean-prod` to remove previous generated code before the build. The production deployment folder will be generated as /deploy-prod/ and contain minified and concatenated Javascript in `/deploy-prod/src/js/index.js` and CSS in `/deploy-prod/src/css/index.css`. We recommend utilizing the `deploy-staging` and `deploy-prod` stub tasks to execute copying deployment folders to staging and production environments.

# Explanation of application architecture

	 .
	 ├── /deploy-prod                   <-- "Production" folder containing html and compressed assets. Generated with the "jake build-prod" task. The contents of this folder is what is deployed to production environments and includes all static assets. 
	 │   └── index.html                 <-- The production-ready file you want to view to launch this webapp.
	 ├── /deploy-debug                  <-- "Development" folder containing and uncompressed and optimized-for-debugging version of your deployment folder.
	 │   └── index.html                 <-- The generated uncompressed version of the html file to use during daily development.
	 ├── /src                           <-- Source files used to generate the deploy-debug and deploy-prod folders
	 │   ├── index.html                 <-- index.html template used to generate the debug and prod versions. Include CSS and JS concat lists between respective markers.
	 │   └── /templates                 <-- Folder of JavaScript view templates, automatically integrated into debug and prod index.html file via jake tasks.
	 │   └── /css                       <-- Folder of CSS files. Add new files to the index.html file between the @css concat@ markers. They will be linked directly in debug deployment folder and minified and concatenated in the production folder. Sass files are automatically converted to CSS via the build script.
	 │   └── /js                        <-- Folder of JS files. Add new files to the index.html file between the @javascript concat@ markers. They will be linked directly in debug deployment folder and minified and concatenated in the production folder.
	 │   └── /images                    <-- Folder for static assets. Static asset folders are symlinked in the deploy-debug folder and copied as is to the prod folder.
	 │   └── /polyfill                  <-- Folder for javascript polyfills. Static folder treated similarly to the /images/ folder. Integrate polyfills in your index.html template using Modernizr.
	 ├── /node_modules                  <-- node.js modules referenced by tasks in the jakeFile
	 └── jakeFile                       <-- node.js equivalent of makeFile. All build and concat watching tasks are defined and run from here.
	 
# Additional tips
* Generated debug and production folders `deploy-debug` and `deploy-prod` are added to `.gitignore` so they aren’t committed to your repository. If using a CVS other then GIT, make sure these folders are not checked in to your CVS.

* There is a plethora of great libraries and utilities included with Mandible2. Its strongly recommended that you read up on each to best utilize the potential of each and to make sure they are working with you not against you.

# To-do
* add unit tests for the node.js scripts
* add stub backbone.js code, possibly namespaced JS scaffolding generated via jake task
* add example project