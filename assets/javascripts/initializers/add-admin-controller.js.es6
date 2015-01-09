export default {
  name: "add-geoffrey-admin",

  initialize: function(container, application) {
    var AdminController = container.lookupFactory("controller:admin");

    if (!AdminController){ return;}

    if (!Discourse.AdminTemplatesAdminView) Discourse.AdminTemplatesAdminView = Discourse.View.extend({});

    Discourse.AdminTemplatesAdminView.reopen({
        insertGeoffreyitemView: function() {
            if(Discourse.User.currentProp('admin')) {
              $(".nav").append('<li><a href="/admin/geoffrey">Geoffrey</a></li>');
            }
        }.on("didInsertElement")
    });

    // Discourse.GeoffreyRoute = Discourse.AdminRoute.extend({
    //  // this is just an empty admin route so that we are shown under the menu, too
    // });

    Discourse.GeoffreyAdminRoute = Discourse.Route.extend({
        model: function() {
            return Discourse.ajax('/admin/geoffrey/config.json');
        },

    });

    Discourse.GeoffreyAdminController = Discourse.AdminController.extend({

        geoffreyIncludeEndpoint: function(){
            return this.get("model.endpoint");
        }.property('model')
    });

  }
};