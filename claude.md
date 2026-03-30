# 🤖 Tido (noteOS) — AI Assistant Context & Audit

## 📌 Contexto del Proyecto
**Tido** (internamente llamado noteOS) es una aplicación macOS nativa de "Menu Bar" (barra de estado), enfocada en ser un gestor de tareas extremadamente rápido, limpio y estéticamente "Premium" (estilo Apple).
- **Stack Tecnológico:** Swift 6, SwiftUI, SwiftData, AppKit (para Hacks de ventana translúcida).
- **Estado Actual (Auditoría):** El proyecto es altamente estable. En la última iteración se optimizaron cuellos de botella en la asincronía (Swift Concurrency en lugar de GCD), cargas de base de datos (`FetchLimit` para calcular órdenes de tareas) y se arreglaron problemas lógicos de persistencia de "Workspaces". Todos los glitches de rebote y animación de la UI han sido erradicados.

---

## 🏗️ Arquitectura y Patrones (OBLIGATORIO)

### 1. Sistema de Diseño (Design Tokens)
**NUNCA** uses constantes crudas para medidas, colores, animaciones o fuentes. Todo pasa por el sistema de diseño centralizado:
- **Archivo:** `Utilities/Constants.swift` (`TidoDesign`)
- `TidoDesign.Color.accent` (No uses `.blue` ni `.gray`).
- `TidoDesign.Spacing.md`, `TidoDesign.Radius.xl`, `TidoDesign.Font.header`.
- `TidoDesign.Animation.spring` (para cualquier cambio de estado UI).

### 2. Gestión de Estados y Base de Datos (MVVM + SwiftData)
Las vistas (`View`) **JAMÁS** deben modificar un modelo `@Model` de SwiftData directamente ni invocar al `ModelContext`. Todo debe pasar obligatoriamente a través del `TaskStore` (`Store/TaskStore.swift`).
- **Lectura:** `@Query` directo en las vistas principales está permitido para la reactividad.
- **Escritura:** `store.toggleTask()`, `store.addTask()`, `store.createWorkspace()`.
- **⚠️ Advertencia Importante de Base de Datos:** Los modelos `TaskItem` y `SubTaskItem` usan una propiedad explícita `var id: UUID`. **NO** elimines este ID para sustituirlo por el `PersistentIdentifier` nativo de SwiftData a la ligera sin implementar una migración de la base de datos (Data Migration Plan), ya que corromperá los datos de los usuarios instalados.

### 3. Componentes y UI Personalizada
Tido no utiliza elementos estándar de SwiftUI si estos se ven "baratos" o lentos ("cheap").
- En lugar de `Picker`, usamos nuestro componente personalizado `FilterTabBar` con soporte deslizante `matchedGeometryEffect`.
- En lugar de un `Toggle` por defecto, usamos nuestro `CheckboxView` animado (con feedback y rotación asíncrona).
- Las entradas de texto rápidas ("Inline generation") dependen de `AddTaskField` el cual tiene gestión de foco manual y se pliega con resorte (animación tipo Spring) cuando haces *submit*.

### 4. Entorno de Ventana de Mac (AppKit + SwiftUI)
La aplicación sobreescribe el comportamiento de una ventana normal generada por `MenuBarExtra` (`.window` style) inyectando en su lugar `Material.ultraThin` y eliminando la barra de título (`titleVisibility = .hidden`).
- Para intervenir la ventana de Mac (`NSWindow`), usamos `NSApplication.shared.windows.first(where: { ... })` protegido dentro de bloques `.task { await MainActor.run { ... } }` con pequeñas esperas (`Task.sleep`) para garantizar que el render de la ventana ya exista en memoria antes de intervenirla.
- El límite de workspaces está visualmente fijado en `10` usando una `Menu` list para evitar que el menú vertical nativo se sobreponga al tamaño visible de resoluciones pequeñas (en las pantallas reducidas de MacBooks antiguos).

---

## 🔍 Reglas para futuros agentes / Claude:
1. Eres un Ingieniero de Software Staff que prioriza el **Performance Front-end y el "Premium Feel"**.
2. Antes de aplicar código, busca si ya existe un control similar en `Components/` o `Extensions/`. No dupliques interfaces.
3. El código debe estar documentado con los típicos separadores `// MARK: - Local State`, `// MARK: - Body`, etc.
4. Cualquier llamada que requiera una espera debe modernizarse con `Task { try? await Task.sleep }` en vez de usar `DispatchQueue`.
5. Valídame cualquier cambio fuerte de arquitectura en el Data Layer antes de meter mano a `SwiftData`.
