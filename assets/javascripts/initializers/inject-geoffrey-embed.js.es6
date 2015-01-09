export default {
  name: "inject-geoffrey-embed",

  initialize: function(container, application) {
    var ApplicationView = container.lookupFactory("view:application");

    ApplicationView.reopen({
        injectGeoffrey: function(){
            if (!Discourse.SiteSettings.geoffrey_endpoint) {
                console.warn("Geoffrey setup incomplete!");
                return;
            }
            console.log("INJECTING");

            // embed at the
            var gfr = document.createElement('script'),
                s = document.getElementsByTagName('script')[0];

            gfr.type = 'text/javascript';
            gfr.async = true;
            gfr.src = Discourse.SiteSettings.geoffrey_endpoint + 'assets/dc-embed.js';

            s.parentNode.insertBefore(gfr, s);
        }.on('didInsertElement')
    });
  }
};
