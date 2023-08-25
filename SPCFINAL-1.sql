create database spc;
use spc;

#Integrantes del equipo:
#Cano Chino Ana Paola
#Delgado Velázquez Josué Jafet
#García Ortiz Angelo Daniel
#González Hernández Juan Diego
#Moctezuma Montoya Isaac
#Vázquez Sotelo Diego Alexis


CREATE TABLE usuario(
 id_usuario INTEGER primary key auto_increment,
 nombre VARCHAR(30) NOT NULL,
 apellido VARCHAR(20),
 correo VARCHAR(70) NOT NULL,
 contrasena VARCHAR(50) NOT NULL
);

CREATE TABLE categoria(
 id_categoria INTEGER primary key auto_increment,
 nombre_cat VARCHAR(50) NOT NULL,
 estado BOOLEAN,
 fk_usuario integer not null references usuario(id_usuario)
);

CREATE TABLE registro_log(
id_registro_log integer auto_increment primary key,
 tabla_afectada varchar(15) not null,
 accion varchar(10) not null,
 fecha_cambio date not null
);
CREATE TABLE cuenta_usuario(
id_cuenta_usuario integer primary key auto_increment,
nombre_banco varchar(20) not null,
numero_cuenta varchar(16) not null,
fk_id_usuario INTEGER not null references usuario (id_usuario)
);

CREATE TABLE reporte(
 id_reporte INTEGER primary key auto_increment,
 monto double not null,
 fecha date not null,
 concepto varchar(255),
 tipo_movimiento varchar(10) not null,
 fk_cuenta_usuario integer not null references cuenta_usuario (id_cuenta_usuario),
 fk_categoria integer references categoria (id_categoria),
 fk_usuarioR integer not null references usuario(id_usuario)
 );

CREATE TABLE historial(
 id_historial INTEGER NOT NULL primary key,
 fecha DATE not null,
 reporte_mov VARCHAR(10),
 fk_reporte INTEGER NOT NULL references reporte (id_reporte)
);


CREATE VIEW v_saldo_usuario AS SELECT
id_usuario,CONCAT(usuario.nombre,'',usuario.apellido) as Usuario,
ROUND((SELECT SUM(monto) FROM reporte WHERE tipo_movimiento='Ingreso')-
(SELECT SUM(monto) FROM reporte WHERE tipo_movimiento='Egreso'),2) AS Saldo FROM
usuario
inner join cuenta_usuario ON cuenta_usuario.fk_id_usuario=usuario.id_usuario
inner join reporte ON cuenta_usuario.id_cuenta_usuario=reporte.fk_cuenta_usuario
INNER JOIN categoria ON reporte.fk_categoria= categoria.id_categoria
GROUP BY id_usuario;


CREATE VIEW v_nombres_categoria AS SELECT
nombre_cat,reporte.fecha as Ultima_modificacion
FROM categoria INNER JOIN reporte ON reporte.fk_categoria= categoria.id_categoria
ORDER BY reporte.fecha DESC;


CREATE VIEW v_modificacion_categoria AS SELECT
COUNT(nombre_cat) AS Modificacion_Categorias,reporte.fecha as Ultima_modificacion
FROM categoria INNER JOIN reporte ON reporte.fk_categoria= categoria.id_categoria
GROUP BY reporte.fecha;


CREATE VIEW v_fecha_accion_registro_log AS SELECT
accion, fecha_cambio AS Fecha FROM registro_log
ORDER BY fecha_cambio desc;


CREATE VIEW v_all_acciones_registro_log AS SELECT
COUNT(accion) AS Total_de_acciones, fecha_cambio AS Fecha FROM registro_log
GROUP BY fecha_cambio;


CREATE VIEW v_resumen_ingresos_reporte AS SELECT
id_reporte,monto,nombre_cat AS Categoria, fecha FROM reporte
INNER JOIN categoria ON reporte.fk_categoria= categoria.id_categoria
WHERE tipo_movimiento='Ingreso'
ORDER BY fecha desc;

CREATE VIEW v_resumen_egresos_reporte AS SELECT
id_reporte,monto,nombre_cat AS Categoria, fecha FROM reporte
INNER JOIN categoria ON reporte.fk_categoria= categoria.id_categoria
WHERE tipo_movimiento='Egreso'
ORDER BY fecha desc;

CREATE VIEW v_ingresos_totales_categoria_reporte AS SELECT
SUM(monto) AS Ingreso_Total,nombre_cat FROM reporte
INNER JOIN categoria ON reporte.fk_categoria= categoria.id_categoria
WHERE tipo_movimiento='Ingreso' 
GROUP BY nombre_cat;


CREATE VIEW v_egresos_totales_categoria_reporte AS SELECT
SUM(monto) AS Egreso_Total,nombre_cat FROM reporte
INNER JOIN categoria ON reporte.fk_categoria= categoria.id_categoria
WHERE tipo_movimiento='Egreso'
GROUP BY nombre_cat;

CREATE VIEW v_cuentas_bancarias_cuenta_usuario AS SELECT
nombre_banco AS Nombre_del_Banco, numero_cuenta AS Numero_de_Cuenta,
CONCAT(usuario.nombre,' ',usuario.apellido) AS Nombre_Usuario
FROM cuenta_usuario
INNER JOIN usuario ON usuario.id_usuario=cuenta_usuario.fk_id_usuario
ORDER BY nombre_banco asc;

CREATE VIEW v_all_cuentas_bancarias_cuenta_usuario AS SELECT
CONCAT(usuario.nombre,' ',usuario.apellido) AS Nombre_Usuario,
COUNT(*) AS Numero_Cuentas_Bancarias
FROM cuenta_usuario
INNER JOIN usuario ON usuario.id_usuario=cuenta_usuario.fk_id_usuario
GROUP BY fk_id_usuario;


CREATE VIEW v_all_historial AS SELECT
fecha,COUNT(reporte_mov) AS Transacciones_del_dia
FROM historial
GROUP BY fecha
ORDER BY fecha desc;


CREATE INDEX id_usuarios ON usuario (id_usuario);

create index Datos_app_usuario on usuario (id_usuario,correo,contrasena);

CREATE UNIQUE INDEX Datos_usuario ON usuario (id_usuario,nombre,apellido);

create index id_categoria on categoria (id_categoria);

create index datos_categoria on categoria (id_categoria,nombre_cat);

create index registro_log on registro_log (id_registro_log);

create index cambios_tablas on registro_log (tabla_afectada,accion,fecha_cambio);

CREATE UNIQUE INDEX fecha_cambios on registro_log (accion,fecha_cambio);

create index id_reporte on reporte (id_reporte);

create index fecha_movimientos on reporte (id_reporte,fecha,tipo_movimiento);

create index id_historial on historial (id_historial);

create index fecha_registro on historial (fecha);

CREATE UNIQUE INDEX historial_reporte_registro on historial
(id_historial,fk_reporte);



DELIMITER $$
create trigger verificacion_categoria before insert on categoria
for each row
begin
declare categoria_blanco varchar(1);
set categoria_blanco='';
if new.nombre_cat<=>categoria_blanco then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se admiten categorias en blanco';
end if;
end; $$


DELIMITER $$
create trigger nom_repetido before update on categoria
for each row
begin
declare nom_viejo varchar(50);
set nom_viejo=old.nombre_cat;
if new.nombre_cat<=> nom_viejo then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay ningun cambio de nombre';
end if;
end; $$


DELIMITER $$
create trigger categoria_usada before delete on categoria
for each row
begin
declare num_categoria integer;
SELECT
 COUNT(*)
INTO num_categoria FROM
 reporte
WHERE
 fk_categoria = old.id_categoria;
if num_categoria>0 then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta categoria se esta usando';
end if;
end; $$


DELIMITER $$
create trigger insert_log after insert on categoria
for each row
begin
insert into registro_log values (0,'Categoria','Insert',curdate());
end;$$


DELIMITER $$
create trigger update_log after update on categoria
for each row
begin
insert into registro_log values (0,'Categoria','Update',curdate());
end;$$


DELIMITER $$
create trigger Delete_log after delete on categoria
for each row
begin
insert into registro_log values (0,'Categoria','Delete',curdate());
end;$$


DELIMITER $$
create trigger verificar_transaccion before insert on historial
for each row
begin
if new.fecha<>curdate() then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha erronea';
end if;
end;$$


DELIMITER $$
create trigger Confirmar_forana before update on historial
for each row
begin
declare nom_viejo varchar(50);
set nom_viejo=old.fk_reporte;
if new.fk_reporte<> nom_viejo then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede modificar este valor';
end if;
end; $$


DELIMITER $$
create trigger fkrepote_uso before delete on historial
for each row
begin
declare epotek integer;
select count(*) into epotek from reporte where id_reporte=old.fk_reporte;
if epotek>0 then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este repoe se esta usando';
end if;
end;$$


DELIMITER $$
create trigger insert_log_H after insert on historial
for each row
begin
insert into registro_log values (0,'Historial','Insert',curdate());
end;$$


DELIMITER $$
create trigger update_log_H after update on Historial
for each row
begin
insert into registro_log values (0,'Historial','Update',curdate());
end;$$



DELIMITER $$
create trigger Delete_log_H after delete on Historial
for each row
begin
insert into registro_log values (0,'usuari','Delete',curdate());
end;$$


DELIMITER $$
create trigger tabla_verificacion before insert on registro_log
for each row
begin
if New.tabla_afectada <> 'usuario' or New.tabla_afectada <> 'reporte' or New.tabla_afectada <>
'categoria'
or New.tabla_afectada <> 'historial' or New.tabla_afectada <> 'registro_log' then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tabla no valida';
end if;
end; $$


DELIMITER $$
create trigger valores_seguimiento before update on registro_log
for each row
begin
if New.tabla_afectada <> 'usuario' or New.tabla_afectada <> 'reporte' or New.tabla_afectada <>
'categoria'
or New.tabla_afectada <> 'historial' or New.tabla_afectada <> 'registro_log' then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Las tablas no pueden ser alteradas';
end if;
end; $$


DELIMITER $$
create trigger Eliminar_mes before delete on registro_log
for each row
begin
declare un_mes date;
select DATE_ADD(old.fecha_cambio,interval 1 month) into un_mes from registro_log where
id_registro_log =old.id_registro_log;
if old.fecha_cambio< un_mes then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede borrar filas de menos de un
mes de antiguedad';
end if;
end;$$


DELIMITER $$
create trigger validacion_cuenta before insert on cuenta_usuario
for each row
begin
declare cuenta_blanco varchar(1);
set cuenta_blanco='';
if new.nombre_banco<=>cuenta_blanco then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se admiten nombre de bancos en blanco';
end if;
end;$$

DELIMITER $$
create trigger cuenta_repetida before update on cuenta_usuario
for each row
begin
declare nom_viejo integer;
set nom_viejo=old.numero_cuenta;
if new.numero_cuenta<=> nom_viejo then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay ningun cambio de numero de cuenta';
end if;
end; $$

DELIMITER $$
create trigger cuenta_uso before delete on cuenta_usuario
for each row
begin
if exists (select * from cuenta_usuario inner join reporte on cuenta_usuario.id_cuenta_usuario=reporte.fk_cuenta_usuario 
where fk_cuenta_usuario=old.id_cuenta_usuario) then
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede borrar esta cuenta';
end if;
end;$$

DELIMITER $$
create trigger insert_log_H_c after insert on cuenta_usuario
for each row
begin
insert into registro_log values (0,'Cuenta','Insert',curdate());
end;$$


DELIMITER $$
create trigger update_log_H_c after update on cuenta_usuario
for each row
begin
insert into registro_log values (0,'cuenta','Update',curdate());
end;$$


DELIMITER $$
create trigger Delete_log_H_c after delete on cuenta_usuario
for each row
begin
insert into registro_log values (0,'Cuenta','Delete',curdate());
end;$$


DELIMITER $$
CREATE PROCEDURE desactivar(id INTEGER) 
BEGIN 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
   START TRANSACTION;
	IF EXISTS(SELECT * FROM categoria WHERE id_categoria = id) THEN 
		UPDATE categoria SET estado=false WHERE id_categoria=id;
        COMMIT;
    END IF;
    SET AUTOCOMMIT=1;
END; $$

DELIMITER $$
CREATE PROCEDURE eliminar_cat(id integer)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
   START TRANSACTION;
 IF NOT EXISTS(SELECT * FROM REPORTE WHERE fk_categoria=id) THEN
	DELETE FROM categoria WHERE id_categoria=id;
    commit;
 END IF;
 set autocommit=1;
END;$$

DELIMITER $$
CREATE PROCEDURE activar(id INTEGER) 
BEGIN 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
   START TRANSACTION;
	IF EXISTS(SELECT * FROM categoria WHERE id_categoria = id) THEN 
		UPDATE categoria SET estado=true WHERE id_categoria=id;
        commit;
    END IF;
    set autocommit=1;
END; $$


DELIMITER $$
CREATE PROCEDURE save_categoria(nombre varchar(255),state boolean, fk int) 
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
   START TRANSACTION;
 IF NOT EXISTS(SELECT * FROM categoria WHERE UPPER(nombre_cat)=UPPER(nombre) AND fk_usuario=fk) THEN
	INSERT INTO categoria (nombre_cat, estado, fk_usuario)  VALUES (nombre, true, fk);
    commit;
    END IF;
    set autocommit=1;
END;$$

DELIMITER $$
CREATE PROCEDURE eliminar_mov(id int)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
   START TRANSACTION;
	IF EXISTS(SELECT * FROM reporte WHERE id_reporte=id) THEN
		DELETE FROM reporte WHERE id_reporte = id;
        commit;
    END IF;
END;$$

DELIMITER $$
CREATE PROCEDURE ver_movs(id int)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
   START TRANSACTION;
	SELECT * from usuario 
    inner join reporte on usuario.id_usuario=reporte.fk_usuarioR
	inner join categoria on reporte.fk_categoria=categoria.id_categoria 
    inner join cuenta_usuario on reporte.fk_cuenta_usuario=cuenta_usuario.id_cuenta_usuario
    where id_usuario=id;
    commit;
    set autocommit=1;
END;$$

DELIMITER $$
CREATE PROCEDURE save_mov(_monto double,_fecha date,_concepto varchar(255),_tipo_movimiento varchar(20),_fk_cuenta int,_fk_cat int,_fk_user int)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
   START TRANSACTION;
	INSERT INTO reporte(monto, fecha, concepto, tipo_movimiento, fk_cuenta_usuario, fk_categoria,fk_usuarior)
    VALUES (_monto,_fecha,_concepto,_tipo_movimiento,_fk_cuenta,_fk_cat,_fk_user);
    commit;
    set autocommit=1;
END;$$

DELIMITER $$
CREATE PROCEDURE ver_cat(id int)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
START TRANSACTION;
	SELECT * FROM categoria WHERE fk_usuario = id;
    commit;
set autocommit=1;
END;$$

DELIMITER $$
CREATE PROCEDURE update_mov(_monto double,_fecha date,_concepto varchar(255),_fk_cat int,_fk_user int,id int)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
   START TRANSACTION;
	UPDATE reporte SET monto=_monto,fecha=_fecha,concepto=_concepto,
		fk_categoria=_fk_cat,fk_usuarioR=_fk_user
    WHERE id_reporte=id;
    commit;
    set autocommit=1;
END;$$


DELIMITER $$
CREATE PROCEDURE save_user(_correo varchar(255),_nombre varchar(255), _contraseña varchar(255))
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		SELECT "error" AS mensaje;
        rollback;
	END;
   SET autocommit=0;
   START TRANSACTION;
	INSERT INTO usuario (correo,nombre,contrasena) VALUES (_correo,_nombre,_contraseña);
    commit;
    set autocommit=1;
END;$$

DELIMITER $$
CREATE PROCEDURE ver_user (_correo varchar(255), _contraseña varchar(255))
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   SET autocommit=0;
   START TRANSACTION;
	SELECT * FROM usuario WHERE correo = _correo AND contrasena = _contraseña;
    commit;
    set autocommit=1;
END;$$

DELIMITER $$
CREATE PROCEDURE save_cuenta_bancaria(_nombre_banco varchar(255),cuenta varchar(255), fk INTEGER)
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   set autocommit=0;
   START TRANSACTION;
   IF (length(cuenta)=16)  THEN
		INSERT INTO cuenta_usuario VALUES (0, _nombre_banco, cuenta, fk);
		COMMIT;
	ELSE 
		SELECT ('El numero de la cuenta debe tener 16 caracteres') AS mensaje;
	END IF;
	set autocommit=1;
END;$$


DELIMITER $$
CREATE PROCEDURE ver_bancos(id int, id_cuenta INTEGER)
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   
   IF id_cuenta IS NOT NULL THEN
		SELECT id_cuenta_usuario, nombre_banco, numero_cuenta from cuenta_usuario WHERE fk_id_usuario=id AND id_cuenta_usuario=id_cuenta;
   ELSE
		SELECT id_cuenta_usuario, nombre_banco, numero_cuenta from cuenta_usuario WHERE fk_id_usuario=id;
   END IF;
END;$$

DELIMITER $$
CREATE PROCEDURE eliminar_cuenta(id integer)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		SELECT "error" AS mensaje;
        rollback;
   END;
   
	IF (EXISTS(SELECT * FROM cuenta_usuario WHERE id_cuenta_usuario=id)AND NOT EXISTS(SELECT * FROM reporte where fk_cuenta_usuario=id) )THEN
		DELETE FROM cuenta_usuario WHERE id_cuenta_usuario=id;
	END IF;
END;$$

DELIMITER $$
CREATE PROCEDURE editar_cuenta_banco(nom_b varchar(255), num_c varchar(255),id int, fk int)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		SELECT "error" AS mensaje;
        rollback;
	END;
   SET autocommit=0;
   START TRANSACTION;
	IF (length(num_c)=16)  THEN
		UPDATE cuenta_usuario SET nombre_banco=nom_b,numero_cuenta=num_c WHERE id_cuenta_usuario=id AND fk_id_usuario=fk;
		COMMIT;
	ELSE 
		SELECT ('El numero de la cuenta debe tener 16 caracteres') AS mensaje;
	END IF;
    commit;
    set autocommit=1;
END;$$
