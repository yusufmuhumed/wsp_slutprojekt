document.addEventListener('DOMContentLoaded', function() {
    const loginButton = document.getElementById('loginButton');
    const accountSymbol = document.getElementById('accountSymbol');
  
    // Get the current route of the website
    const currentRoute = window.location.pathname;
  
    // Assuming '/todos' is the route when the user is logged in
    const isLoggedIn = currentRoute === '/todos';
  
    if (isLoggedIn) {
      // User is logged in, hide login button and show account symbol
      loginButton.style.display = 'none';
      accountSymbol.style.display = 'block';
    } else {
      // User is not logged in, hide account symbol and show login button
      loginButton.style.display = 'block';
      accountSymbol.style.display = 'none';
    }
  });
  