# EatEase

<img src="https://raw.githubusercontent.com/jDxve/EatEase/main/assets/images/logo.png" alt="EatEase Logo" width="400" />


## Overview

EatEase is a modern food ordering mobile application built with Flutter that provides users with a seamless experience for browsing restaurants, ordering food, and making secure online payments. The app features real-time order tracking, in-app messaging, and multiple payment options through PayMongo integration.

## Features

- **User Authentication**: Secure login, registration, and password reset system
- **Restaurant Browsing**: Browse restaurants by category, location, or rating
- **Menu Management**: View restaurant menus with detailed food descriptions
- **Cart System**: Add items to cart and modify quantities
- **Order Tracking**: Real-time order status updates
- **Online Payments**: Secure payment integration with PayMongo (GCash, GrabPay, PayMaya, and credit cards)
- **Order History**: View past orders and reorder favorite items
- **In-app Chat**: Direct messaging between customers and restaurants
- **Profile Management**: Update user details and manage addresses
- **Real-time Notifications**: Receive updates on order status

## Tech Stack

### Mobile Application
- **Flutter**: Cross-platform UI framework for building native applications
- **Dart**: Programming language for Flutter development
- **Provider/Bloc**: State management
- **Socket.io Client**: Real-time communication
- **Flutter Secure Storage**: Secure storage for user credentials

### Backend
- **Node.js**: JavaScript runtime for server-side development
- **Express**: Web framework for Node.js
- **MongoDB**: NoSQL database for data storage
- **Mongoose**: MongoDB object modeling for Node.js
- **Socket.io**: Real-time bidirectional event-based communication
- **JWT**: JSON Web Tokens for authentication
- **Bcrypt**: Password hashing
- **Nodemailer**: Email service for password reset

### Payment Processing
- **PayMongo**: Online payment gateway integration for Philippines

## Installation

### Prerequisites
- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- Node.js (14.x or higher)
- MongoDB (4.4 or higher)
- Android Studio or VS Code with Flutter extensions

### Mobile App Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/eatease.git

# Navigate to the project directory
cd eatease

# Install dependencies
flutter pub get

# Run the application
flutter run
```

### Backend Setup
```bash
# Navigate to the backend directory
cd backend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env file with your configuration

# Start the server
npm run dev
```

## Environment Variables

Create a `.env` file in the backend directory with the following:

```
PORT=5001
MONGO_URI=mongodb+srv://EatEase_Root:DAVE907039@eatease-cluster1.zfxxb.mongodb.net/EatEaseDB
API_BASE_URL=http://139.59.76.138:5001/api
SOCKET_BASE_URL=http://139.59.76.138:5001

PAYMONGO_SECRET_KEY=sk_test_ud4EFbLxhHYzYPTLRQaue6wF
PAYMONGO_PUBLIC_KEY=pk_test_nsm6ji7LNchBRpGRQedARonR

EMAIL_USER=eatease9@gmail.com
EMAIL_PASS=axfc tvhb bhgy ngkt
```

## API Documentation

The API is built using RESTful principles:

### Authentication
- `POST /api/users/register` - Register a new user
- `POST /api/users/login` - Login and get user ID
- `POST /api/auth/request-verification-code` - Request password reset code
- `POST /api/auth/verify-code` - Verify password reset code
- `POST /api/auth/reset-password` - Reset user password

### User Management
- `GET /api/users/:id` - Get user profile information
- `PUT /api/users/:id` - Update user profile information

### Restaurants
- `GET /api/restaurants` - Get all active restaurants
- `GET /api/restaurants/:id` - Get restaurant details
- `GET /api/restaurants/:restaurantId/menu` - Get restaurant menu items
- `GET /api/categories` - Get all food categories

### Orders
- `POST /api/orders` - Create a new order
- `GET /api/orders/:customer_id` - Get user's cart
- `PUT /api/orders/:customer_id` - Update order stage and pickup time
- `DELETE /api/orders/:customer_id/items/:item_id` - Remove item from cart
- `DELETE /api/orders/:customer_id/items` - Clear cart
- `PUT /api/orders/:customerId/items/:itemId` - Update item quantity
- `GET /api/place_orders/:userId` - Get pending orders
- `GET /api/orders/:userId/completed` - Get completed orders
- `PUT /api/cancel_order/:orderId` - Cancel an order
- `PUT /api/update_order/:orderId` - Mark order as picked up
- `POST /api/orders/:orderId/rate` - Rate a completed order

### Payments
- `POST /api/create-payment` - Create payment source or intent
- `GET /api/payment-status/:id` - Check payment status
- `POST /api/payments` - Record payment information
- `GET /api/payments/order/:orderId` - Get payment details for an order

### Chat
- `POST /api/chats` - Create a new chat
- `POST /api/chats/:chatId/messages` - Send a message
- `GET /api/chats/:chatId/messages` - Get chat messages
- `GET /api/users/:userId/chats` - Get all user chats
- `GET /api/users/:userId/contacts` - Get user contacts
- `GET /api/chats/users/:userId/restaurants/:restaurantId` - Get specific chat

## Socket.IO Events

EatEase uses Socket.IO for real-time communication:

### Client Events (Emit)
- `joinChat` - Join a specific chat room
- `sendMessage` - Send a message to a chat

### Server Events (Listen)
- `messageReceived` - Receive a new message
- `error` - Handle error notifications

## Deployment

### Mobile App
- Generate APK/App Bundle: `flutter build apk` or `flutter build appbundle`
- Deploy to Google Play Store or App Store

### Backend
- Currently deployed on Digital Ocean droplet at IP: 139.59.76.138
- MongoDB Atlas cluster for database storage
- PM2 for process management

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Your Name - your.email@example.com

Project Link: [https://github.com/yourusername/eatease](https://github.com/yourusername/eatease)
