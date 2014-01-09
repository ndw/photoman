var map;
var markers = [];

var lineWidth = 1;
var lineColor = '#ff0000';

function showMap(lat,lng) {
    var latlng = new google.maps.LatLng(lat,lng)
    var mapopts = {
        zoom: 15,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.HYBRID
    };

    var mapDiv = document.getElementById('map');
    map = new google.maps.Map(mapDiv, mapopts);

    createPoint(map, lat, lng, "Location");
}

function showMapGroup(pts) {
    var pos, marker, pt;
    var mapDiv = document.getElementById('map');
    var latlng = new google.maps.LatLng(pts[0].lat, pts[0].lng);
    var bounds = new google.maps.LatLngBounds(latlng, latlng);
    var mapopts = {
        "zoom": 15,
        "center": latlng,
        "mapTypeId": google.maps.MapTypeId.HYBRID
    };

    map = new google.maps.Map(mapDiv, mapopts);

    for (pos = 0; pos < pts.length; pos++) {
        latlng = new google.maps.LatLng(pts[pos].lat, pts[pos].lng);
        bounds.extend(latlng);
        marker = createMarker(pts[pos]);
    }

    map.fitBounds(bounds);
}

function createMarker(pt) {
    var latlng = new google.maps.LatLng(pt.lat, pt.lng);
    var marker = new google.maps.Marker({
        "position": latlng,
        "map": map,
        "title": pt.title
    });

    var a = "<a href='" + pt.uri + "'>";
    var content = "<div class='infowindow'>";
    content += a + "<img src='" + pt.square + "'></a> ";

    if (pt.title == "") {
        content += a + "<i>untitled</i></a>";
    } else {
        content += a + pt.title + "</a>";
    }

    content += "</div>";

    var info = new google.maps.InfoWindow({
        "content": content
    });

    google.maps.event.addListener(marker, "click", function() {
        info.open(map, marker);
    });
}

function createPoint(map, lat, lng, title) {
    var latlng = new google.maps.LatLng(lat, lng);
    var marker = new google.maps.Marker({
        position: latlng,
        map: map,
        title: title
    });
}
