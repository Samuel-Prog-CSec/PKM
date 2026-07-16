---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - TLS
Fecha de actualización: 2026-07-14
Nota previa: "[[08 - SSL Stripping]]"
Nota siguiente: "[[10 - Downgrade Attacks]]"
Area: "[[HTTPs-TLS.base|HTTPs/TLS]]"
---
---

Además de los padding oracles y la compresión, otros ataques golpean **los propios algoritmos** cuando son débiles o están mal usados. En la práctica de 2026 casi ninguno se explota end-to-end; su valor real es que <mark style="background: #FF5582A6;">te enseñan **qué primitivas marcar como hallazgo**</mark> durante la auditoría TLS. Esta nota es la referencia de "cripto que no debería estar ahí".

# LUCKY13: el padding oracle que vuelve por timing

Para cerrar los [[03 - Padding Oracle Attacks|padding oracles]], los servidores dejaron de dar errores verbosos y empezaron a **calcular el MAC aunque el padding fuese inválido**, buscando un tiempo de respuesta constante. **Lucky13** (2013) explota que ese cálculo del MAC <mark style="background: #FFB8EBA6;">incluye los bytes de padding incorrectos</mark>, así que tarda ligeramente distinto según el caso. Esa diferencia de timing minúscula vuelve a ser un oráculo de padding que puede recuperar el plaintext. Parcheado en 2013 por casi todas las librerías; **hoy no aparece** en engagements reales.

# SWEET32: colisiones en bloques de 64 bits

**Sweet32** (2016) es un **birthday attack** contra cifradores de bloque **corto** (64 bits) como `3DES` o `Blowfish`. El objetivo es encontrar una **colisión** de bloques; en modo CBC, una colisión filtra el XOR de dos bloques de plaintext. Requiere capturar <mark style="background: #FFB8EBA6;">cientos de gigabytes</mark> sobre **una misma conexión de larga vida** (horas/días), lo que lo hace poco práctico. La cura es TLS 1.3 (elimina los cifradores de bloque corto) o, en TLS 1.2, desactivar `3DES`.

# FREAK y Logjam: la herencia de los cifradores *export*

**FREAK** (*Factoring RSA Export Keys*, 2015) explota los **export cipher suites**: cifradores deliberadamente débiles (claves RSA de 512 bits) que EE.UU. imponía en los 90 para poder exportar software criptográfico. Un servidor que aún ofrezca `RSA_EXPORT` puede ser **forzado** a usar esa clave de 512 bits, factorizable hoy en horas por unos pocos dólares en la nube. Se combina con un [[10 - Downgrade Attacks|downgrade]] para forzar el suite débil.

> [!info] Logjam (2015), el gemelo de FREAK sobre Diffie-Hellman
> HTB no lo menciona, pero **Logjam** es el equivalente contra `DHE_EXPORT`: fuerza un Diffie-Hellman de 512 bits. Su parte inquietante es la **precomputación**: muchos servidores comparten los mismos primos DH de 512/1024 bits, así que un atacante con recursos (nación-estado) puede precomputar y romper `1024-bit DH` para **millones** de servidores. Es la razón por la que hoy se exige DH ≥ 2048 bits o, mejor, `ECDHE`.

# RC4: roto sin remedio

Tras [[04 - POODLE y BEAST|BEAST]] se recomendó `RC4` como alternativa a CBC… y `RC4` resultó tener **sesgos estadísticos** explotables: los ataques de AlFardan et al. (2013), *Bar Mitzvah* y sobre todo **RC4 NOMORE** (Vanhoef, 2015) demostraron la recuperación de cookies capturando suficiente tráfico. `RC4` quedó **prohibido** (RFC 7465). Verlo activo es un hallazgo directo.

# Checklist de primitivas a marcar en un pentest

Esta es la utilidad real de la nota — lo que un escáner TLS reporta y tú justificas:

| Categoría | Marcar como hallazgo |
| - | - |
| Protocolos | SSLv2, SSLv3, TLS 1.0, TLS 1.1 |
| Cifradores | `RC4`, `DES`, `3DES` (SWEET32), `EXPORT`, `NULL`, `aNULL` (anónimos) |
| Key exchange | Sin PFS (`TLS_RSA_*` estático), DH < 2048 bits (Logjam) |
| Tamaño de clave | RSA < 2048 bits |
| Firmas | `MD5`, `SHA-1` en certificados |
| Modo | CBC en TLS 1.0 (BEAST/Lucky13) frente a `AEAD` |

<mark style="background: #FF5582A6;">Casi todo esto desaparece con una configuración *TLS 1.2+/1.3 con solo suites `AEAD` y `ECDHE`*</mark>. TLS 1.3 no admite ninguna de estas primitivas débiles por diseño.

> [!success] Cómo se detecta y se puntúa
> No se explota: se **escanea**. `testssl.sh`, `sslscan` y `sslyze` listan protocolos y cifradores y marcan Lucky13/Sweet32/FREAK/Logjam/RC4 con nombre propio. Para el veredicto se usan referencias de la industria:
> - **Qualys SSL Labs** (grado A+ … F).
> - **Mozilla SSL Configuration Generator** (perfiles *Modern / Intermediate / Old*) — el estándar para recomendar la config correcta en el informe.
>
> ```shell-session
> $ testssl.sh --std --fs target.htb     # protocolos, cifradores y forward secrecy
> $ sslscan target.htb
> ```
> El flujo completo de auditoría está en [[11 - Detección, testeo y hardening de TLS]].

## Referencias

- [Lucky13](http://www.isg.rhul.ac.uk/tls/Lucky13.html) · [Sweet32](https://sweet32.info/) · [FREAK](https://mitls.org/pages/attacks/SMACK#freak) · [Logjam](https://weakdh.org/)
- [RC4 NOMORE (Vanhoef, 2015)](https://www.rc4nomore.com/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
