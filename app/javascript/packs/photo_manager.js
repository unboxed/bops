function hasNavigator() {
  return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia)
}

document.addEventListener('turbo:load', e => {
  e.preventDefault();
  const video = document.querySelector('video');

  console.log("potato");

  const constraints =  {
    video: {
      width: { min: 288, ideal: 288 },
      height: { min: 301, ideal: 301 }
    }
  }

  if (hasNavigator()) {
    if (video) {
      navigator.mediaDevices.getUserMedia(constraints)
      .then((stream) => {
        var video = document.getElementById("vid");
        var canvas = document.getElementById("drawing-canvas");
        var button = document.getElementById("photo-button");
        var imageDiv = document.querySelector('images-go-here')

        video.srcObject = stream;
        video.play();
        button.disabled = false;
        button.onclick = function() {
          canvas.getContext("2d").drawImage(video, 0, 0, 300, 300, 0, 0, 300, 300);
          var img = canvas.toDataURL("image/png");
          imageDiv.appendChild(img);
          alert("done");
        };
      })
      .catch((err) => {
        document.body.textContent = 'Could not access the camera. Error: ' + err.name;
        console.log(err.name + ": " + err.message);
      });
    }
  } else {
    console.log("camera not found");
  }
})