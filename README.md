# EatEase

<img src="https://raw.githubusercontent.com/jDxve/EatEase/main/assets/images/logo.png" alt="EatEase Logo" width="400" />


# Overview

EatEase is a modern food ordering mobile application built with Flutter that provides users with a seamless experience for browsing restaurants, ordering food, and making secure online payments. The app features real-time order tracking, in-app messaging, and multiple payment options through PayMongo integration.

# Features

  User Authentication: 
    Secure login, registration, and password reset system
    
  Restaurant Browsing: 
    Browse restaurants by category, location, or rating
    
  Menu Management: 
    View restaurant menus with detailed food descriptions
    
  Cart System: 
    Add items to cart and modify quantities
    
  Order Tracking: 
    Real-time order status updates
    
  Online Payments: 
    Secure payment integration with PayMongo (GCash and GrabPay)
    
  Order History:
    View past orders and reorder favorite items
    
  In-app Chat: 
    Direct messaging between customers and restaurants
    
  Profile Management: 
    Update user details and manage addresses


# Tech Stack

  Mobile Application

    Flutter: Cross-platform UI framework for building native applications
    Dart: Programming language for Flutter development

  Backend

    Node.js: JavaScript runtime for server-side development
    Express: Web framework for Node.js
    MongoDB: NoSQL database for data storage
    Mongoose: MongoDB object modeling for Node.js
    Socket.io: Real-time bidirectional event-based communication
    JWT: JSON Web Tokens for authentication
    Bcrypt: Password hashing
    Nodemailer: Email service for password reset


# Installation

  Prerequisites
      Flutter SDK (2.10.0 or higher)
      Dart SDK (2.16.0 or higher)
      Node.js (14.x or higher)
      MongoDB (4.4 or higher)
      Android Studio or VS Code with Flutter extensions

# Mobile App Setup
  
  1. Clone the repository:
     
       git clone https://github.com/jDxve/EatEase.git
     
  2. Navigate to the project directory:

        cd eatease
     
  3. Install dependencies:

        flutter pub get
     
  4. Run the application:

       flutter run

# Backend Setup:

  1. Navigate to the backend directory:
     
       cd backend
     
  2. Install dependencies:

        npm install
     
  3. Set up environment variables:

       Create a .env file in the backend directory with the following:

          PORT=5001
          MONGO_URI=mongodb+srv://[username]:[password]@[cluster].mongodb.net/EatEaseDB
          API_BASE_URL=http://localhost:5001/api
          SOCKET_BASE_URL=http://localhost:5001
          
          PAYMONGO_SECRET_KEY=sk_test_your_secret_key
          PAYMONGO_PUBLIC_KEY=pk_test_your_public_key
          
          EMAIL_USER=eatease9@gmail.com
          EMAIL_PASS=your_app_password
     
  4. Start the server:

       npm run dev or node server.js


# Developer Contact Information

  Developer: 
      John Dave Bañas
      
  Email: 
      johndavebanas03@gmail.com
      
  LinkedIn: 
      linkedin.com/in/john-dave-bañas-560a8634a
      
  Facebook: 
      facebook.com/johndave.banas.16
