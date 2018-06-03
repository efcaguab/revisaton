// load global vars
var global_params;
$.ajax({
  url: "json-data/global-vars.json",
  dataType: 'json',
  async: false,
  success: function (json) {
    global_params = json
  }
});

    $(document).ready(function () {

      // determine progress
      $(function(){
        var prec = 1000;
        var rate = global_params.rate;
        var current_count = Number(global_params.n_submissions) + Number((Date.now() - global_params.max_date) * rate) / 1000
        var progress = Math.round(current_count / 94250 * 100 * prec) / prec
        $("#progress").html(progress);
        $("#main-progress-bar").html(Math.round(progress) + "%")
        $("#main-progress-bar").css("width", Math.round(progress) + "%")
      });

      // determine form
      $(function () {
        $.getJSON("json-data/dep.json", function (json) {
          var wl_dep = new WeightedList(json);
          var this_dep = wl_dep.peek();
          $("#show-dep").html(this_dep);
          $.getJSON("json-data/dep/" + this_dep + ".json", function (json_mun) {
            var wl_mun = new WeightedList(json_mun);
            var this_mun = wl_mun.peek();
            $("#show-mun").html(this_mun);
            $.getJSON("json-data/mun/" + this_dep + "/" + this_mun + ".json", function (json_zon) {
              var wl_zon = new WeightedList(json_zon);
              var this_zon = wl_zon.peek();
              $("#show-zon").html(this_zon);
              $.getJSON("json-data/pto/" + this_dep + "/" + this_mun + "/" + this_zon + ".json", function (json_pto_full) {
                var json_pto = json_pto_full.df
                var i = Math.floor(Math.random() * json_pto.length);
                var this_mes = json_pto[i];
                $("#no").attr("value", this_mes[1]);
                setup_download_button(this_mes);
                setup_form_title(this_mes);
                setup_form_metadata(json_pto_full.dep, json_pto_full.mun, this_mes);
              });
            });
          });

          function setup_download_button(mesa_file) {
            var prefix = "https://visor.e14digitalizacion.com/e14_divulgacion/";
            $("#form-download-button").attr("href", prefix + mesa_file[0]);
            $("#form-download-button").html("Descargar formulario " + expand_form_name(mesa_file[1]));
          };

          function setup_form_title(mesa_file) {
            var prefix = "Encontraste algún problema en el formulario ";
            var suffix = "?"
            $("#form-title").html(prefix + expand_form_name(mesa_file[1]) + suffix);
          };

          function expand_form_name(form_name) {
            var expanded_form_name = form_name.substring(0, 1) + "-" + form_name.substring(1, 3) + "-" + form_name.substring(3, 5) + "-" + form_name.substring(5, 7);
            return expanded_form_name
          };

          function setup_form_metadata(dep, mun, mesa){
            $("#form-metadata").html("la mesa " +  mesa[3] + " de " + mesa[2] + " en " + mun + ", " + dep)

          };

        });
      });

      // control logic of form
      $(function () {
        function checkIfAnomalyFound() {
          if ($("#inlineRadio1").is(":checked")) {
            $("#anomaly-found").prop('disabled', false);
            $('#anomaly-found').show();
          } else {
            $("#anomaly-found").prop('disabled', true);
            $('#anomaly-found').hide();
          }
        }

        $("#inlineRadio1").change(checkIfAnomalyFound);
        $("#inlineRadio2").change(checkIfAnomalyFound);

        // actions on submit: end email to local storage and timestamp
        $("#the-form").submit(function () {
          if (typeof (Storage) !== "undefined") {
            var email = $("#emailInput").val();
            localStorage.setItem("email", email);
            this_submission_date = Date.now()
            localStorage.setItem("lastSubmission", this_submission_date)
            localStorage.setItem("notification", document.getElementById('notificationInput').checked)
            // array with submissions
            if (localStorage.getItem("n_submissions") == null || localStorage.getItem("n_submissions") == undefined) {
              var n_submissions = 1;
              localStorage.setItem("n_submissions", JSON.stringify(n_submissions));
            } else {
              var n_submissions = JSON.parse(localStorage.getItem("n_submissions"));
              n_submissions = Number(n_submissions) + 1;
              localStorage.setItem("n_submissions", JSON.stringify(n_submissions));
            }

          } else {
            // Sorry! No Web Storage support..
          }
        });

        $("#form-download-button").click(function () {
          $("#main-question").prop('disabled', false);
          $("#email-fieldset").prop('disabled', false);
          $("#sendButton").prop('disabled', false);
        });
      });

      // establish ip 
      $(function () {
        $.getJSON("https://api.ipify.org?format=jsonp&callback=?",
          function (json) {
            $("#ip").attr("value", json.ip);
          }
        );
      });

      // establish fields on load (id, email, checked, ncontributiobs)
      $(function () {
        if (typeof (Storage) !== "undefined") {
          // establish id
          if (localStorage.getItem("id") == null) {
            var id = '_' + Math.random().toString(36).substr(2, 9);
            localStorage.setItem("id", id);
            $("#id").attr("value", id);
          } else {
            $("#id").attr("value", localStorage.getItem("id"));
          }
          // establish email
          if (!(localStorage.getItem("email") == null || localStorage.getItem("email") == undefined || localStorage.getItem("email") == "")) {
            $("#emailInput").attr("value", localStorage.getItem("email"));
          }
          var n_submissions = localStorage.getItem("n_submissions")
          if (!(n_submissions == null || n_submissions == undefined)){
            if(localStorage.getItem("n_submissions") > 1){
              $("#n-submisions-div").css("display", "block");
              $("#n-submissions-info").html(n_submissions);
            }
          }
          // establish checked
          if (!(localStorage.getItem("notification") == null || localStorage.getItem("notification") == undefined)){
            document.getElementById('notificationInput').checked = localStorage.getItem("notification");
          }
        } else {
          // Sorry! No Web Storage support..
        }
      });
    });

    // alert logic
    $(function () {

      var alerts = {
        "basic" : "<div class='alert alert-success fade show py-1' role='alert' id='submission-successful-alert'><strong>Gracias!</strong> Si puedes, revisa un formulario más o <a href='http://www.revisar-e14.com/#share'>comparte</a> esta página con tus amigos.</div>", 
        "third" : "<div class='alert alert-info fade show py-1' role='alert' id='submission-successful-alert'>Super. <strong>Ya vas 3!</strong> Si puedes dale otro poquito. La mayoría de personas revisa <span id='mean-submissions'></span> o más. </div>",
        "mean_minus_one" : "<div class='alert alert-info fade show py-1' role='alert' id='submission-successful-alert'>Super. <strong>Ya vas <span id='n-submissions-alert'></span>!</strong> Una más y habrás hecho más que el 50% de las personas.</div>", 
        "max" : "<div class='alert alert-info fade show py-1' role='alert' id='submission-successful-alert'><strong>Una nota!</strong> El ciudadano más comprometido ya lleva <span id='max-submissions'></span> formularios. Te mides al reto?.</div>"
      }

      function success_alert(alert_html, n_submissions) {
        
        $("#alert-container").html(alert_html);
        $("#mean-submissions").html(global_params.mean_contribution_user);
        $("#max-submissions").html(global_params.max_contribution_user);
        $("#n-submissions-alert").html(n_submissions);
        setTimeout(function () {
          $("#submission-successful-alert").alert('close')
        }, 10000);
      };

      if (typeof (Storage) !== "undefined") {
        if ((Date.now() - localStorage.getItem("lastSubmission") < 5000)) {
          var n_submissions = JSON.parse(localStorage.getItem("n_submissions"));
          if(n_submissions == 3){
            success_alert(alerts.third, n_submissions)
          } else if(n_submissions == global_params.mean_contribution_user - 1) {
            success_alert(alerts.mean_minus_one, n_submissions)
          } else if(n_submissions == Number(global_params.mean_contribution_user) + 5){
            success_alert(alerts.max)
          } else {
            success_alert(alerts.basic);
          }
          
        }
      } else {
        // Sorry! No Web Storage support..
      }
    });

$(function () {
  $('[data-toggle="tooltip"]').tooltip()
})