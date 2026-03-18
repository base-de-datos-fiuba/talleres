# Taller: Restricciones en SQL

## Contexto

Se dispone de una base de datos del **Mundial de Fútbol Qatar 2022** con las siguientes tablas:

- **teams**: información estadística de cada selección participante.
- **matches**: partidos disputados, con los equipos, goles y fase del torneo.

El script de creación inicial es el siguiente:

```sql
CREATE TABLE teams (
    team            VARCHAR(20) NOT NULL,
    players_used    INT         NOT NULL,
    avg_age         FLOAT       NOT NULL,
    possession      FLOAT       NOT NULL,
    games           INT         NOT NULL,
    goals           INT         NOT NULL,
    assists         INT         NOT NULL,
    cards_yellow    INT         NOT NULL,
    cards_red       INT         NOT NULL
);

CREATE TABLE matches (
    team1       VARCHAR(20)     NOT NULL,
    team2       VARCHAR(20)     NOT NULL,
    goals_team1 INT             NOT NULL,
    goals_team2 INT             NOT NULL,
    stage       VARCHAR(30)     NOT NULL
);
```

Los datos se cargan desde archivos CSV con el siguiente comando:

```sql
COPY teams   FROM '/teams.csv'   CSV HEADER DELIMITER ';' ENCODING 'LATIN1';
COPY matches FROM '/matches.csv' CSV HEADER DELIMITER ';' ENCODING 'LATIN1';
```

---

## Ejercicio 1 — Exploración inicial

Ejecute el script de creación de las tablas y carga de datos. Luego explore el contenido de ambas tablas con `SELECT * FROM ...`.

---

## Ejercicio 2 — Restricciones de clave primaria

De acuerdo con el modelo relacional propuesto, identifique qué atributos conforman la **clave primaria** de cada tabla.

Modifique los `CREATE TABLE` del script, definiendo una `CONSTRAINT` de `PRIMARY KEY` en cada tabla. Asigne un nombre descriptivo a cada constraint (por ejemplo: `pk_teams` y `pk_matches`).

> Referencia: https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-PRIMARY-KEYS

Vuelva a ejecutar el script completo (incluyendo los `DROP TABLE IF EXISTS`) y verifique la estructura resultante con:

```sql
\d+ teams
\d+ matches
```

---

## Ejercicio 3 — Verificación I: violación de unicidad

Intente provocar una violación a la restricción de unicidad de la tabla `teams` a través de un `INSERT` con un equipo que ya exista en la tabla.

¿Qué mensaje de error devuelve el motor? ¿Qué restricción fue violada?

---

## Ejercicio 4 — Restricciones de clave foránea

Analice en cuál de las dos tablas existe una **clave foránea** y qué atributos la conforman.

Modifique el `CREATE TABLE` correspondiente en el script, definiendo una `CONSTRAINT` de `FOREIGN KEY`. Asigne un nombre a la constraint y ejecute el script completo.

> Referencia: https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-FK

Vuelva a verificar la estructura con `\d+ teams` y `\d+ matches`.

---

## Ejercicio 5 — Verificación II: inserción de una referencia inexistente

Intente provocar una violación a la restricción de integridad referencial a través de un `INSERT` en la tabla que considere apropiada, referenciando un equipo que **no exista** en `teams`.

¿Qué mensaje de error devuelve el motor?

---

## Ejercicio 6 — Verificación III: eliminación de una tupla referenciada

Intente provocar una violación a la restricción de integridad referencial a través de un `DELETE` en la tabla que considere apropiada, intentando eliminar un equipo que **sí esté referenciado** en `matches`.

¿Qué mensaje de error devuelve el motor?

---

## Ejercicio 7 — Verificación IV: actualización de una tupla referenciada

Intente modificar el nombre del equipo `'ARGENTINA'` por `'ARG'` utilizando un `UPDATE`. ¿Es posible realizarlo con la configuración actual? ¿Por qué?

---

## Ejercicio 8 — Actualización en cascada

Las autoridades de la FIFA quieren poder cambiar el nombre de los equipos por sus diminutivos, actualizando automáticamente todas las filas que hacen referencia a ellos en otras tablas.

Modifique el script de `CREATE TABLE` correspondiente, definiendo una acción `ON UPDATE` en la constraint de clave foránea.

Vuelva a ejecutar el script completo con los datos cargados.

---

## Ejercicio 9 — Verificación V: actualización en cascada

Intente nuevamente modificar el nombre del equipo `'ARGENTINA'` por `'ARG'`.

Luego verifique el resultado consultando ambas tablas:

```sql
SELECT * FROM teams  WHERE team = 'ARG';
SELECT * FROM matches WHERE team1 = 'ARG' OR team2 = 'ARG';
```

¿Qué ocurrió en la tabla `matches`? ¿Por qué?

---

## Ejercicio 10 — Eliminación en cascada

Las autoridades de la FIFA insertaron al equipo `'CHILE'` por error en el mundial y necesitan eliminarlo, borrando automáticamente todos los registros relacionados en otras tablas.

Modifique el script de `CREATE TABLE` correspondiente, definiendo también una acción `ON DELETE` en la constraint de clave foránea.

Luego vuelva a ejecutar el script completo, inserte manualmente los datos de prueba indicados a continuación y ejecute las consultas de verificación:

```sql
INSERT INTO teams (team, players_used, avg_age, possession, games, goals, assists, cards_yellow, cards_red)
VALUES ('CHILE', 0, 0, 0, 0, 0, 0, 0, 0);

INSERT INTO matches (team1, team2, goals_team1, goals_team2, stage)
VALUES ('ARGENTINA', 'CHILE', 4, 1, 'Quarterfinals');

SELECT * FROM teams  WHERE team = 'CHILE';
SELECT * FROM matches WHERE team1 = 'CHILE' OR team2 = 'CHILE';
```

---

## Ejercicio 11 — Verificación VI: eliminación en cascada

Intente nuevamente eliminar el equipo `'CHILE'` de la tabla `teams`.

Luego verifique el resultado:

```sql
SELECT * FROM teams  WHERE team = 'CHILE';
SELECT * FROM matches WHERE team1 = 'CHILE' OR team2 = 'CHILE';
```

¿Qué ocurrió en la tabla `matches`? ¿Por qué?
