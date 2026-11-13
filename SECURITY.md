# 🛡️ Política de Seguridad del Proyecto REP

## Descripción General

Este documento describe la arquitectura de seguridad y las políticas para el proyecto REP. Nuestro objetivo es garantizar la confidencialidad, integridad y disponibilidad de los datos de estudiantes y profesores.

## 🚨 Reporte de Vulnerabilidades

Si encuentras una vulnerabilidad de seguridad, por favor **NO abras un issue público**.
Envía un reporte detallado a: `security@mirepapp.com` (o contacta al Tech Lead directamente).

## 🏗️ Arquitectura de Seguridad

### 1. Comunicación (Data in Transit)
- **HTTPS/TLS 1.2+**: Obligatorio para todas las comunicaciones con `/api`.
- **Certificate Pinning**: Recomendado para aplicaciones en producción.
- **Validación de Certificados**: Estricta (`QSslSocket::VerifyPeer`).

### 2. Almacenamiento (Data at Rest)
- **Tokens (JWT)**: NUNCA se almacenan en texto plano en archivos de configuración o código.
  - **Linux**: Uso de `libsecret` / GNOME Keyring / KWallet.
  - **Windows**: Windows Credential Manager.
  - **macOS**: Apple Keychain.
- **Implementación**: Se debe usar la abstracción `ICredentialStore` para interactuar con estos servicios.

### 3. Autenticación
- **JWT (JSON Web Tokens)**: Stateless authentication.
- **Expiración**: Tokens deben expirar en corto tiempo (e.g., 30 min).
- **Rotación**: Implementación de Refresh Tokens segura.

## 🚫 Prácticas Prohibidas
1. **Hardcoding de credenciales** en código fuente.
2. **Logging de datos sensibles** (passwords, tokens, PII).
3. **Desactivar validación SSL** en entornos que no sean explicitamente `DEBUG`.
4. **Commit de archivos `.env` o llaves privadas** al repositorio.

## 🔄 Proceso de Actualización de Dependencias
- Revisión mensual de librerías de terceros (Qt, OpenSSL, etc.).
- actualización inmediata ante CVEs críticos.

---
*Última actualización: Febrero 2026*
