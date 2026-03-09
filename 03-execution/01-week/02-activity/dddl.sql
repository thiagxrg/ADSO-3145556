CREATE DATABASE CoffeeShop;
GO
USE CoffeeShop;
GO;

/*  MODULO 1 - SEGURIDAD */

CREATE TABLE Person (
    id INT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150)
);

CREATE TABLE Role (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200)
);

CREATE TABLE [User] (
    id INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    id_person INT,
    FOREIGN KEY (id_person) REFERENCES Person(id)
);

CREATE TABLE UserRole (
    id_user INT,
    id_role INT,
    PRIMARY KEY (id_user, id_role),
    FOREIGN KEY (id_user) REFERENCES [User](id),
    FOREIGN KEY (id_role) REFERENCES Role(id)
);

CREATE TABLE Module (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(200)
);

CREATE TABLE RoleModule (
    id_role INT,
    id_module INT,
    PRIMARY KEY (id_role, id_module),
    FOREIGN KEY (id_role) REFERENCES Role(id),
    FOREIGN KEY (id_module) REFERENCES Module(id)
);

CREATE TABLE ViewModule (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    id_module INT,
    FOREIGN KEY (id_module) REFERENCES Module(id)
);

CREATE TABLE Action (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE ViewAction (
    id_view INT,
    id_action INT,
    id_role INT,
    PRIMARY KEY (id_view, id_action, id_role),
    FOREIGN KEY (id_view) REFERENCES ViewModule(id),
    FOREIGN KEY (id_action) REFERENCES Action(id),
    FOREIGN KEY (id_role) REFERENCES Role(id)
);

/* MODULO 2 - PARAMETRIZACION */

CREATE TABLE Company (
    id INT PRIMARY KEY,
    name VARCHAR(150),
    nit VARCHAR(50),
    address VARCHAR(200),
    phone VARCHAR(20)
);

CREATE TABLE Tax (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    percentage DECIMAL(5,2)
);

CREATE TABLE PaymentMethod (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE BillStatus (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

/* MODULO 3 - INVENTARIO*/

CREATE TABLE Category (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE Product (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    id_category INT,
    FOREIGN KEY (id_category) REFERENCES Category(id)
);

CREATE TABLE Inventory (
    id INT PRIMARY KEY,
    id_product INT,
    stock INT NOT NULL,
    FOREIGN KEY (id_product) REFERENCES Product(id)
);

/* MODULO 4 - VENTAS */

CREATE TABLE Client (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20)
);

CREATE TABLE Bill (
    id INT PRIMARY KEY,
    id_client INT,
    id_status INT,
    id_payment_method INT,
    id_tax INT,
    date DATETIME DEFAULT GETDATE(),
    subtotal DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    total DECIMAL(10,2),
    FOREIGN KEY (id_client) REFERENCES Client(id),
    FOREIGN KEY (id_status) REFERENCES BillStatus(id),
    FOREIGN KEY (id_payment_method) REFERENCES PaymentMethod(id),
    FOREIGN KEY (id_tax) REFERENCES Tax(id)
);

CREATE TABLE BillDetail (
    id INT PRIMARY KEY,
    id_bill INT,
    id_product INT,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_bill) REFERENCES Bill(id),
    FOREIGN KEY (id_product) REFERENCES Product(id)
);