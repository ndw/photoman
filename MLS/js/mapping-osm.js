/* JS */
var map
var cloudmadeApiKey = "5cc7d716065c41b3af78634e7f69be48"

function setupMap() {
    map = L.map('map')
    L.tileLayer('http://{s}.tile.cloudmade.com/'+cloudmadeApiKey+'/997/256/{z}/{x}/{y}.png', {
	attribution: 'Map &copy; <a href="http://openstreetmap.org">OSM</a>, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a>'
    }).addTo(map);
}

function showMapGroup(pts) {
    var ptll, popup, a, content, myIcon

    setupMap()

    ptll = new Array(pts.length)
    for (i = 0; i < pts.length; i++) {
        ptll[i] = L.latLng(pts[i].lat, pts[i].lng)

        myIcon = L.icon({ iconUrl: pts[i].square,
                          iconSize: [32, 32] })

        popup = L.marker([pts[i].lat, pts[i].lng], { icon: myIcon })
        popup.addTo(map)

        a = "<a href='" + pts[i].uri + "'>";
        content = "<div class='infowindow'>";
        content += a + "<img src='" + pts[i].square + "'></a> ";

        if (pts[i].title == "") {
            content += a + "<i>untitled</i></a>";
        } else {
            content += a + pts[i].title + "</a>";
        }

        popup.bindPopup(content)
    }

    map.fitBounds(ptll)
}

function showTrack(track) {
    var ptll, line, ti

    ptll = new Array(track.length)
    for (i = 0; i < track.length; i++) {
        ptll[i] = L.latLng(track[i].lat, track[i].lng)
    }

    line = L.polyline(ptll, {color: "red"}).addTo(map)
}
