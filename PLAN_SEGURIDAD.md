# Plan de remediación de seguridad — AprendIA

Backlog priorizado de los 18 hallazgos. No se atacan todos de golpe: se agrupan
por **fases**, ordenadas por (impacto × urgencia × esfuerzo). Cada ítem indica
su **viabilidad**, en qué **repo** vive y los **pasos** de corrección.

Leyenda de esfuerzo: 🟢 fácil (<30 min) · 🟡 medio (1–3 h) · 🔴 grande (arquitectura).

> Nota de honestidad sobre el review: el hallazgo #1 describe "CBC con IV
> estático". El código real usa **AES-256-GCM con IV aleatorio por operación**
> (correcto). El único problema válido de #1 es la **llave fija**. Vale aclararlo
> en la defensa.

---

## FASE 0 — Secretos ya expuestos (hacer primero)

Lo urgente no es solo corregir, es que **ya están en el historial de Git**.
Corregir el archivo no borra lo que ya se subió.

### 0.1 · Credenciales del keystore en texto plano — #3 🟢 · app
`android/app/build.gradle.kts` tiene `storePassword`/`keyPassword` = "VirtualSign2026",
y `virtualsign.keystore` está versionado. Es la llave de firma de la app.

Pasos:
1. Crear `android/key.properties` (NO versionado):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=virtualsign
   storeFile=../../virtualsign.keystore
   ```
2. En `build.gradle.kts`, leer de ese archivo en vez de hardcodear.
3. Agregar a `.gitignore`: `key.properties` y `*.keystore`.
4. `git rm --cached virtualsign.keystore` (dejar de rastrearlo).
5. **Como ya se filtró:** para una app real habría que regenerar el keystore.
   Para el integrador, documentarlo como riesgo conocido si no se ha publicado
   en Play Store.

### 0.2 · Validar longitud mínima de JWT_SECRET — #18 🟢 · backend
Un `JWT_SECRET` corto da una clave HMAC débil.

Pasos:
1. Al arrancar, validar que el secreto tenga ≥32 bytes; si no, fallar rápido
   (excepción en el bean de configuración JWT).
2. Confirmar que el `.env` del VPS use un secreto largo y aleatorio.

---

## FASE 1 — Quick wins de backend (una sesión, alto impacto)

### 1.1 · CORS permisivo — #5 🟢 · backend
`SecurityConfig.java`: `allowedOriginPatterns("*")` + `allowCredentials(true)`.

Pasos:
1. Cambiar `*` por la lista real: dominio de producción + `localhost` para dev.
2. Idealmente, leer los orígenes de configuración (`application.yaml`) por entorno.

### 1.2 · Sin límite de longitud en `text` — #8 🟢 · backend
`GenerateSignsRequest.text` no tiene tope; el cliente limita a 200 pero la API no.
Riesgo: texto enorme → FFmpeg satura CPU.

Pasos:
1. Agregar `@Size(max = 200, message = "...")` al campo `text` del record.

### 1.3 · Normalización de email — #7 🟢 · backend
`Usuario@x.com` y `usuario@x.com` se tratan como cuentas distintas.

Pasos:
1. En registro y login, normalizar con `email.trim().toLowerCase()` antes de
   comparar/persistir (en `AuthService`).
2. Considerar índice único sobre el email ya normalizado.

### 1.4 · Falta `.trim()` en el backend — #15 🟢 · backend
El backend confía en que el cliente recorta espacios.

Pasos:
1. En el servicio, aplicar `.trim()` a los campos de texto antes de persistir.
   (Se resuelve junto con 1.3.)

### 1.5 · Path traversal parcialmente mitigado — #9 🟡 · backend
El chequeo de `".."` por substring es débil.

Pasos:
1. En los 3 puntos donde se arma una ruta desde input (streaming de dicc./videos):
   construir `Path base = Paths.get(baseDir).normalize()` y el destino
   `base.resolve(input).normalize()`.
2. Verificar `destino.startsWith(base)`; si no, rechazar con 400.

---

## FASE 2 — Quick wins de cliente (Flutter)

### 2.1 · Cleartext traffic — #6 (parte 1) 🟢 · app
`usesCleartextTraffic="true"` y `apiBaseUrl` ya apunta a HTTPS en prod.

Pasos:
1. Quitar/poner en `false` `usesCleartextTraffic` en el Manifest.
2. Confirmar que `AppConstants.apiBaseUrl` sea siempre HTTPS en release.

### 2.2 · Validación de email inconsistente + duplicada — #13, #14 🟢 · app
Distintas pantallas validan email/contraseña con reglas distintas.

Pasos:
1. Crear un `Validators` compartido (un solo regex de email, una sola regla de
   contraseña) y usarlo en `login_screen` y `register_screen`.

### 2.3 · Complejidad de contraseña — #10 🟡 · ambos
Solo se exige longitud ≥8.

Pasos:
1. Definir la política (mayúscula/número/símbolo) en el `Validators` del cliente.
2. Replicarla en el backend con `@Pattern` en `RegisterRequest`.
   (Coordinar con 2.2 para no duplicar.)

### 2.4 · Mensajes de error sin filtrar en SnackBar — #16 🟢 · app
Hoy sin riesgo alto (el backend cuida sus mensajes), pero sin defensa en profundidad.

Pasos:
1. Mapear errores conocidos a mensajes amigables; para el resto, un mensaje genérico.

---

## FASE 3 — Esfuerzo medio, alto valor

### 3.1 · Llave AES fija — #1 (parcial) 🟡 · app
Recordatorio: el IV y el modo (GCM) ya están bien. Solo la **llave** es fija.

Pasos:
1. Al primer arranque, generar una llave AES-256 aleatoria.
2. Guardarla en `flutter_secure_storage` (Keychain iOS / Keystore Android).
3. Leer la llave de ahí en vez de la constante `_key`.
4. Migrar datos existentes o invalidarlos (forzar re-login).

### 3.2 · Sin rate limiting en `/auth/login` — #2 🟡 · backend
Permite fuerza bruta de contraseñas.

Pasos:
1. Agregar Bucket4j (o un contador en memoria/Redis) por IP + cuenta.
2. Tras N intentos fallidos, bloqueo temporal (p. ej. 5 intentos / 15 min).
3. Responder 429 con `Retry-After`.

### 3.3 · IDOR en `POST /history` — #4 🟡 · backend
`generatedFilename` se acepta sin validar que el archivo lo generó ese usuario.
Combinado con `DELETE /history/{id}`, permite tocar recursos ajenos.

Pasos:
1. Al guardar historial, validar que el `generatedFilename` fue generado en esta
   sesión/por este usuario (registrar quién generó cada archivo, o firmar el
   nombre con un token corto).
2. El `DELETE` ya valida pertenencia por `findByIdAndUser` — confirmar que sí.

### 3.4 · Casts de JSON no defensivos (Dart) — #11 🟡 · app
`as String` / `as int` directos producen el engañoso "No se pudo conectar con el
servidor" ante cualquier cambio de contrato.

Pasos:
1. En los modelos, validar tipos antes del cast o usar `json_serializable`.
2. Separar "error de red" de "error de formato" en el manejo.

---

## FASE 4 — Estructural / producción (planear, no urge para MVP)

### 4.1 · `ddl-auto: update` en producción — #12 🔴 · backend
Hibernate modifica el esquema en cada arranque: riesgo operativo real.

Pasos:
1. Integrar Flyway (o Liquibase) con migraciones versionadas.
2. En producción, cambiar a `ddl-auto: validate`.
3. Generar la migración inicial desde el esquema actual.

### 4.2 · Certificate pinning — #6 (parte 2) 🟡 · app
Sin pinning, un MITM con CA comprometida podría interceptar.

Pasos:
1. Fijar el certificado/clave pública del dominio en `ApiClient`.
2. Ojo: hay que rotarlo cuando renueve el certificado (Cloudflare).
   Evaluar si vale la complejidad para el alcance del proyecto.

### 4.3 · Sin análisis estático en el backend — #17 🟢 · backend
El cliente ya tiene `flutter_lints`; el backend no.

Pasos:
1. Agregar SpotBugs o Checkstyle al `pom.xml`.
2. Correrlo en el build y limpiar los hallazgos que valga la pena.

---

## Orden recomendado

1. **Fase 0** — los secretos expuestos, primero (minutos, y son lo más grave).
2. **Fase 1** — quick wins de backend (una tarde, mucho impacto).
3. **Fase 2** — quick wins de cliente.
4. **Fase 3** — los tres de esfuerzo medio con más valor de seguridad real.
5. **Fase 4** — dejar planeada; para el MVP se puede documentar como "trabajo
   futuro" con justificación, salvo `@Size` de FFmpeg que ya está en Fase 1.

## Qué es "necesario" vs "documentable" para la entrega

- **Necesario corregir:** Fase 0 completa, 1.1 (CORS), 1.2 (@Size), 3.2 (rate
  limiting), 3.3 (IDOR). Son los que un revisor de seguridad probaría en vivo.
- **Muy recomendable:** el resto de Fase 1 y 2 (baratos, se ven bien).
- **Documentable como trabajo futuro si falta tiempo:** 4.1 (Flyway), 4.2
  (pinning) — con justificación de alcance MVP.
