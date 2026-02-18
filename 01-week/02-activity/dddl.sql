create database CoffeShop;
use CoffeShop;
go;


create table clients{
    id int primary key,
    name varchar(100) not null,
};

create table Products{
    id int primary key,
    name varchar(100) not null,
    price decimal(10,2) not null,
    category varchar(100) not null,
};

create table Orders{
    id int primary key,
    id_client int,
    subtotal decimal(10,2) not null,
    foreign key (id_client) references client(id)
};

create table DetailOrder{
    id int primary key,
    id_order int,
    id_product int,
    quantity int not null,
    total decimal(10,2) not null,
    foreign key (id_order) references Orders(id),
    foreign key (id_product) references Products(id)
};
