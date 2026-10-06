use app;

/****************
****SECURITY*****
****************/

INSERT INTO role (code, name, status)
VALUES ('ADMIN', 'Administrador', true);

INSERT INTO role (code, name, status)
VALUES ('COORD', 'Coordinador', true);

INSERT INTO role (code, name, status)
VALUES ('GUEST', 'Invitado', true);

SELECT * FROM role;

INSERT INTO person (first_name, last_name, address, phone, email, status)
VALUES ('Juan', 'Lopez', 'Calle 10 #15-20', '3001234567', 'juan.lopez@sena.edu.co', true);

INSERT INTO person (first_name, last_name, address, phone, email, status)
VALUES ('Maria', 'Gomez', 'Carrera 8 #22-14', '3012345678', 'maria.gomez@sena.edu.co', true);

INSERT INTO person (first_name, last_name, address, phone, email, status)
VALUES ('Carlos', 'Ramirez', 'Avenida 30 #45-11', '3023456789', 'carlos.ramirez@sena.edu.co', true);

INSERT INTO person (first_name, last_name, address, phone, email, status)
VALUES ('Laura', 'Martinez', 'Transversal 19 #7-33', '3034567890', 'laura.martinez@sena.edu.co', false);

select * from person;

INSERT INTO `user` (`user`, password, person_id, role_id)
VALUES (
    'jlopez',
    'Clave123*',
    (SELECT id FROM person WHERE email = 'juan.lopez@sena.edu.co' LIMIT 1),
    (SELECT id FROM role WHERE code = 'ADMIN' LIMIT 1)
);

INSERT INTO `user` (`user`, password, person_id, role_id)
VALUES (
    'mgomez',
    'Clave123*',
    (SELECT id FROM person WHERE email = 'maria.gomez@sena.edu.co' LIMIT 1),
    (SELECT id FROM role WHERE code = 'COORD' LIMIT 1)
);

INSERT INTO `user` (`user`, password, person_id, role_id)
VALUES (
    'cramirez',
    'Clave123*',
    (SELECT id FROM person WHERE email = 'carlos.ramirez@sena.edu.co' LIMIT 1),
    (SELECT id FROM role WHERE code = 'GUEST' LIMIT 1)
);

SELECT * FROM `user`;

-- Se quiere validar el reporte de personas con usuario.  [nombre_completo, user, pws]
select 
	concat(p.first_name,' ',p.last_name) name,
    u.user,
    u.password
from 
	person p
    inner join `user` u on p.id = u.person_id
    inner join role r on u.role_id = r.id;


/*********************
****SHOPPING CART*****
**********************/

INSERT INTO category (code, name, description, status)
VALUES ('CAT-TECH', 'Tecnologia', 'Productos tecnologicos y accesorios', true);

INSERT INTO category (code, name, description, status)
VALUES ('CAT-OFF', 'Papeleria', 'Articulos de oficina y estudio', true);

INSERT INTO category (code, name, description, status)
VALUES ('CAT-HOME', 'Hogar', 'Productos de apoyo para espacios del hogar', true);

SELECT * FROM category;

INSERT INTO product (code, name, description, price, count, status, category_id)
VALUES (
    'PROD-MOUSE',
    'Mouse Optico',
    'Mouse USB ergonomico',
    45000.00,
    25,
    true,
    (SELECT id FROM category WHERE code = 'CAT-TECH' LIMIT 1)
);

INSERT INTO product (code, name, description, price, count, status, category_id)
VALUES (
    'PROD-KEY',
    'Teclado Multimedia',
    'Teclado USB con teclado numerico',
    80000.00,
    18,
    true,
    (SELECT id FROM category WHERE code = 'CAT-TECH' LIMIT 1)
);

INSERT INTO product (code, name, description, price, count, status, category_id)
VALUES (
    'PROD-NOTE',
    'Cuaderno Ejecutivo',
    'Cuaderno argollado de 100 hojas',
    8500.00,
    60,
    true,
    (SELECT id FROM category WHERE code = 'CAT-OFF' LIMIT 1)
);

INSERT INTO product (code, name, description, price, count, status, category_id)
VALUES (
    'PROD-PEN',
    'Lapicero Negro',
    'Lapicero tinta gel color negro',
    2500.00,
    120,
    true,
    (SELECT id FROM category WHERE code = 'CAT-OFF' LIMIT 1)
);

INSERT INTO product (code, name, description, price, count, status, category_id)
VALUES (
    'PROD-LAMP',
    'Lampara LED',
    'Lampara de escritorio recargable',
    120000.00,
    12,
    true,
    (SELECT id FROM category WHERE code = 'CAT-HOME' LIMIT 1)
);

SELECT * FROM product;

/****************
******BILL*******
****************/

INSERT INTO bill (date, total_value, discount_total, total_tax, status, person_id)
VALUES (
    '2026-04-01',
    125000.00,
    4000.00,
    23750.00,
    true,
    (SELECT id FROM person WHERE email = 'juan.lopez@sena.edu.co' LIMIT 1)
);

INSERT INTO bill (date, total_value, discount_total, total_tax, status, person_id)
VALUES (
    '2026-04-02',
    131000.00,
    12000.00,
    24890.00,
    true,
    (SELECT id FROM person WHERE email = 'maria.gomez@sena.edu.co' LIMIT 1)
);

INSERT INTO bill (date, total_value, discount_total, total_tax, status, person_id)
VALUES (
    '2026-04-03',
    125000.00,
    4500.00,
    23750.00,
    true,
    (SELECT id FROM person WHERE email = 'carlos.ramirez@sena.edu.co' LIMIT 1)
);

SELECT * FROM bill;

/************************
******BILL DETAIL*******
************************/

INSERT INTO bill_detail (total_value, discount_percentage, total_tax, product_id, bill_id)
VALUES (
    45000.00,
    0.00,
    8550.00,
    (SELECT id FROM product WHERE code = 'PROD-MOUSE' LIMIT 1),
    (SELECT id FROM bill WHERE date = '2026-04-01' AND person_id = (SELECT id FROM person WHERE email = 'juan.lopez@sena.edu.co' LIMIT 1) LIMIT 1)
);

INSERT INTO bill_detail (total_value, discount_percentage, total_tax, product_id, bill_id)
VALUES (
    80000.00,
    5.00,
    15200.00,
    (SELECT id FROM product WHERE code = 'PROD-KEY' LIMIT 1),
    (SELECT id FROM bill WHERE date = '2026-04-01' AND person_id = (SELECT id FROM person WHERE email = 'juan.lopez@sena.edu.co' LIMIT 1) LIMIT 1)
);

INSERT INTO bill_detail (total_value, discount_percentage, total_tax, product_id, bill_id)
VALUES (
    8500.00,
    0.00,
    1615.00,
    (SELECT id FROM product WHERE code = 'PROD-NOTE' LIMIT 1),
    (SELECT id FROM bill WHERE date = '2026-04-02' AND person_id = (SELECT id FROM person WHERE email = 'maria.gomez@sena.edu.co' LIMIT 1) LIMIT 1)
);

INSERT INTO bill_detail (total_value, discount_percentage, total_tax, product_id, bill_id)
VALUES (
    2500.00,
    0.00,
    475.00,
    (SELECT id FROM product WHERE code = 'PROD-PEN' LIMIT 1),
    (SELECT id FROM bill WHERE date = '2026-04-02' AND person_id = (SELECT id FROM person WHERE email = 'maria.gomez@sena.edu.co' LIMIT 1) LIMIT 1)
);

INSERT INTO bill_detail (total_value, discount_percentage, total_tax, product_id, bill_id)
VALUES (
    120000.00,
    10.00,
    22800.00,
    (SELECT id FROM product WHERE code = 'PROD-LAMP' LIMIT 1),
    (SELECT id FROM bill WHERE date = '2026-04-02' AND person_id = (SELECT id FROM person WHERE email = 'maria.gomez@sena.edu.co' LIMIT 1) LIMIT 1)
);

INSERT INTO bill_detail (total_value, discount_percentage, total_tax, product_id, bill_id)
VALUES (
    80000.00,
    0.00,
    15200.00,
    (SELECT id FROM product WHERE code = 'PROD-KEY' LIMIT 1),
    (SELECT id FROM bill WHERE date = '2026-04-03' AND person_id = (SELECT id FROM person WHERE email = 'carlos.ramirez@sena.edu.co' LIMIT 1) LIMIT 1)
);

INSERT INTO bill_detail (total_value, discount_percentage, total_tax, product_id, bill_id)
VALUES (
    45000.00,
    10.00,
    8550.00,
    (SELECT id FROM product WHERE code = 'PROD-MOUSE' LIMIT 1),
    (SELECT id FROM bill WHERE date = '2026-04-03' AND person_id = (SELECT id FROM person WHERE email = 'carlos.ramirez@sena.edu.co' LIMIT 1) LIMIT 1)
);

SELECT * FROM bill_detail;
