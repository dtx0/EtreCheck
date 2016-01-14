var isChrome = !!window.chrome;

// Detect Chrome and add some hacks.
if(isChrome)
  {
  var link = document.createElement("link")
    
  link.setAttribute("rel", "stylesheet")
  link.setAttribute("type", "text/css")
  link.setAttribute("href", "css/chrome.css")
  
  document.getElementsByTagName("head")[0].appendChild(link)
  }
  