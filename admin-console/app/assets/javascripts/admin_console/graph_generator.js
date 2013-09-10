function create_apps_per_domain_histogram() {
  jQuery.ajax({
    url: "/admin-console/stats/apps_per_domain",
    dataType: "json",
    success: _finish_apps_per_domain_histogram
  });
}

function _finish_apps_per_domain_histogram(response) {
  histogram_from_bins(compress_long_tail_bins(response.bins), document.getElementById("apps_per_domain"), "Applications", "Domains");
}

function create_gears_per_user_histogram() {
  jQuery.ajax({
    url: "/admin-console/stats/gears_per_user",
    dataType: "json",
    success: _finish_gears_per_user_histogram
  });
}

function _finish_gears_per_user_histogram(response) {
  histogram_from_bins(compress_long_tail_bins(response.bins), document.getElementById("gears_per_user"), "Gears", "Users");
}

function create_domains_per_user_histogram() {
  jQuery.ajax({
    url: "/admin-console/stats/domains_per_user",
    dataType: "json",
    success: _finish_domains_per_user_histogram
  });
}


function _finish_domains_per_user_histogram(response) {
  histogram_from_bins(compress_long_tail_bins(response.bins), document.getElementById("domains_per_user"), "Domains", "Users");
}

// bins - an array of objects with bin label and count
// node - the DOM node to generate the graph in
function histogram_from_bins(bins, node, xlbl, ylbl) {
  //calculate total items
  var total = 0;
  for (var i = 0; i < bins.length; i++)
    total += bins[i].count;
  //make the total evenly divisble by ten for whole number marker lines
  total += 10 - total % 10
  var div = document.createElement("div");
    div.className = "histogram";
    var ylabel = document.createElement("div");
      ylabel.className = "histogram-y-label";
      ylabel.appendChild(document.createTextNode(ylbl));
    div.appendChild(ylabel);
    var content = document.createElement("div");
      content.className = "histogram-content";
      var yaxis = document.createElement("div");
        yaxis.className = "histogram-y-axis";
      for (var i = 10; i <= 100; i+=10) {
        var pct = 100-i;
        var value = Math.round((total * pct) / 100);
        var lbl = document.createElement("span");
          lbl.className = "histogram-label";
          lbl.appendChild(document.createTextNode(value));
        yaxis.appendChild(lbl);
      }

      content.appendChild(yaxis);
      var bars = document.createElement("div");
        bars.className = "histogram-bars";
        var span = document.createElement("span");
          span.className = "histogram-force-height";
        bars.appendChild(span);
      content.appendChild(bars);
      var xaxis = document.createElement("div");
        xaxis.className = "histogram-x-axis";
      content.appendChild(xaxis);    
      for (var i = 0; i < bins.length; i++) {
        var bin = bins[i];
        var bar = document.createElement("span");
          bar.className = "histogram-bar"
          bar.style.height = ((bin.count / total) * 100) + "%";
        bars.appendChild(bar);
        var lbl = document.createElement("span");
          lbl.className = "histogram-label";
          lbl.appendChild(document.createTextNode(bin.bin));
        xaxis.appendChild(lbl);
      }
      for (var i = 0; i <= 100; i+=10) {
        var line = document.createElement("div");
          line.className = "histogram-line";
          line.style.top = i + "%";
        bars.appendChild(line);
      }      
      var xlable = document.createElement("div");
        xlable.className = "histogram-x-label";
        xlable.appendChild(document.createTextNode(xlbl));
      content.appendChild(xlable);
    div.appendChild(content);
  node.appendChild(div);
}

// Compresses bins of bin size 1 into bins of 0, 1, 2-4, 5-10, 11-30, and so on
// bins - an array of objects with bin label and count, expects bin size of 1 and max bin size of 100
function compress_long_tail_bins(bins) {
  var new_bins = [
    {bin: "0", count: 0},
    {bin: "1", count: 0},
    {bin: "2 - 4", count: 0},
    {bin: "5 - 10", count: 0},
    {bin: "11 - 30", count: 0},
    {bin: "31 - 50", count: 0},
    {bin: "51 - 70", count: 0},
    {bin: "71 - 90", count: 0},
    {bin: "91 - 100+", count: 0}
  ];

  for (var i = 0; i < bins.length; i++) {
    var bin = bins[i];
    if (bin.bin == 0)
      new_bins[0].count += bin.count;
    else if (bin.bin == 1)
      new_bins[1].count += bin.count;
    else if (bin.bin >= 2 && bin.bin <= 4)
      new_bins[2].count += bin.count;
    else if (bin.bin >= 5 && bin.bin <= 10)
      new_bins[3].count += bin.count;
    else if (bin.bin >= 11 && bin.bin <= 30)
      new_bins[4].count += bin.count;
    else if (bin.bin >= 31 && bin.bin <= 50)
      new_bins[5].count += bin.count;
    else if (bin.bin >= 51 && bin.bin <= 70)
      new_bins[6].count += bin.count;
    else if (bin.bin >= 71 && bin.bin <= 90)
      new_bins[7].count += bin.count;
    else
      new_bins[8].count += bin.count;
  }

  return new_bins;
}