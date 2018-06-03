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
        var current_count = Number(global_params.n_submissions) + Number((Date.now() - global_params.max_date) * rate)
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
            if (localStorage.getItem("submissions") == null || localStorage.getItem("submissions") == undefined) {
              var submissions = [this_submission_date]
              localStorage.setItem("submissions", JSON.stringify(submissions));
            } else {
              var submissions = JSON.parse(localStorage.getItem("submissions"));
              submissions.push(Date.now());
              localStorage.setItem("submissions", submissions);
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

      // establish unique fields
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
          // establish cjecked
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
        "basic" : "<div class='alert alert-success fade show py-1' role='alert' id='submmission-successful-alert'><strong>Gracias!</strong> Si puedes, revisa un formulario más o <a href='http://www.revisar-e14.com/#share'>comparte</a> esta página con tus amigos.</div>", 
        "third" : "<div class='alert alert-success fade show py-1' role='alert' id='submmission-successful-alert'><strong>Super!</strong> Ya has revisado .</div>" 
      }

      function success_alert(alert_html) {
        
        $("#alert-container").html(alert_html)
        setTimeout(function () {
          $("#submmission-successful-alert").alert('close')
        }, 10000);
      };

      if (typeof (Storage) !== "undefined") {
        if ((Date.now() - localStorage.getItem("lastSubmission") < 5000)) {
        
          success_alert(alerts.basic);
        }
      } else {
        // Sorry! No Web Storage support..
      }
    });
