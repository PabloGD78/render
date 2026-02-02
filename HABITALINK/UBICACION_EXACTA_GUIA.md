# 📍 Guía: Sistema de Ubicación Exacta en HabitaLink

## Descripción General
El sistema de ubicación exacta garantiza que cuando un usuario sube una propiedad con coordenadas específicas en el formulario de subida, esas **mismas coordenadas exactas** se muestren en el mapa del detalle de la propiedad.

---

## Flujo de Funcionamiento

### 1. **Formulario de Subida** (`new_property_card_page.dart`)
   
#### ¿Qué hace?
- El usuario ingresa una ubicación de texto (ej: "Plaza de la Encarnación, Sevilla")
- Presiona el botón de búsqueda 🔍
- El sistema usa **Nominatim (OpenStreetMap)** para convertir el texto a coordenadas precisas
- Las coordenadas se muestran en un mapa con un marcador rojo exacto
- Se muestran las coordenadas exactas: `Lat: XX.XXXXXX, Lon: XX.XXXXXX`

#### Campos guardados:
```
latitude  → Latitud exacta (ej: 37.3891)
longitude → Longitud exacta (ej: -5.9845)
```

#### Requisitos:
- ✅ **OBLIGATORIO**: Si escribes una ubicación, debes hacer clic en la lupa para buscarla
- ✅ Las coordenadas se validan antes de enviar el formulario
- ✅ El zoom del mapa es **15** para consistencia visual

---

### 2. **Base de Datos** (`habitaLink-backend/models/propiedadModel.js`)

#### Columnas en tabla `inmueble_anuncio`:
```sql
latitude DECIMAL(9, 6)  -- Almacena latitud exacta
longitude DECIMAL(9, 6) -- Almacena longitud exacta
```

#### Datos guardados:
```sql
INSERT INTO inmueble_anuncio 
    (id, ..., latitude, longitude) 
VALUES 
    (?, ..., 37.3891, -5.9845)
```

---

### 3. **Recuperación de Datos** (`property_service.dart`)

#### Métodos usados:
- `obtenerTodas()` → Trae todas las propiedades con sus coordenadas
- `obtenerPropiedadDetalle(id)` → Trae una propiedad específica

#### Campos devueltos:
```json
{
  "id": "uuid",
  "titulo": "Casa en Sevilla",
  "latitude": 37.3891,
  "longitude": -5.9845,
  ...
}
```

---

### 4. **Modelo Property** (`property_model.dart`)

#### Conversión JSON → LatLng:
```dart
location: LatLng(
  _parseToDouble(json['latitude']),   // Latitud exacta
  _parseToDouble(json['longitude']),  // Longitud exacta
),
```

#### Fallback de seguridad:
- Si latitude = 0 Y longitude = 0 → Usa coordenadas por defecto de Sevilla
- `LatLng(37.3891, -5.9845)` (Plaza de España)

---

### 5. **Página de Detalle** (`property_detail_page.dart`)

#### ¿Qué hace?
- Obtiene la propiedad cargada desde el controlador
- Extrae las coordenadas exactas usando `getValidLocation(property)`
- Muestra el mapa **exactamente centrado** en esas coordenadas
- El zoom es **15** para consistencia con el formulario
- Muestra un marcador rojo **exactamente en el punto de ubicación**

#### Mapa mostrado:
```dart
FlutterMap(
  options: MapOptions(
    center: location,  // ✅ Coordenadas exactas
    zoom: 15           // ✅ Zoom consistente
  ),
  markers: [
    Marker(
      point: location,  // ✅ Marcador exactamente aquí
      child: Icon(Icons.location_on, color: Colors.red, size: 40)
    )
  ]
)
```

---

## Flujo Visual

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USUARIO SUBE PROPIEDAD                                   │
│    "Plaza de la Encarnación, Sevilla"                       │
│    [Presiona lupa 🔍]                                       │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. NOMINATIM BUSCA COORDENADAS                              │
│    API: nominatim.openstreetmap.org                         │
│    Respuesta: latitude=37.3891, longitude=-5.9845           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. MAPA DE PREVIEW MUESTRA UBICACIÓN                        │
│    Mapa centrado en Lat: 37.3891, Lon: -5.9845              │
│    Marcador rojo exactamente aquí                           │
│    Zoom: 15                                                 │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. USUARIO PUBLICA ANUNCIO                                  │
│    Envía: latitude=37.3891, longitude=-5.9845               │
│    + titulo + descripción + fotos                           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. BACKEND GUARDA EN BD                                     │
│    INSERT INTO inmueble_anuncio                             │
│    (latitude, longitude) VALUES (37.3891, -5.9845)          │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. USUARIO VE DETALLE DE PROPIEDAD                          │
│    GET /api/propiedades/{id}                                │
│    Backend devuelve: latitude=37.3891, longitude=-5.9845    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. FLUTTER CONVIERTE A LatLng                               │
│    LatLng(37.3891, -5.9845)                                 │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. MAPA DE DETALLE MUESTRA UBICACIÓN EXACTA                │
│    ✅ Centrado exactamente en: 37.3891, -5.9845             │
│    ✅ Marcador rojo exactamente aquí                        │
│    ✅ Zoom: 15 (consistente con preview)                    │
│    ✅ UBICACIÓN EXACTA GARANTIZADA                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Cambios Realizados

### ✅ `new_property_card_page.dart`
1. **Mejorada función `buscarUbicacion()`**
   - Ahora muestra mensajes de éxito/error más claros
   - Muestra la ubicación encontrada
   - Mejor manejo de errores

2. **Mapa de preview mejorado**
   - Muestra las coordenadas exactas en un badge verde
   - Zoom consistente de 15
   - Indicador visual de precisión

3. **Validación en `_submitForm()`**
   - Si hay texto en ubicación, REQUIERE que se haya buscado (coords != null)
   - Mensaje claro: "Por favor, busca la ubicación haciendo clic en la lupa 🔍"
   - Envía coordenadas exactas al servidor

### ✅ `property_detail_page.dart`
1. **Mejorada función `_buildLocationWithFlutterMap()`**
   - Documenta que muestra la ubicación exacta registrada
   - Zoom consistente de 15
   - Comentarios claros sobre precisión
   - Marcador exactamente en las coordenadas guardadas

### ✅ Backend (`propiedadController.js`)
- ✅ Captura correctamente `latitude` y `longitude`
- ✅ Convierte a Number para precisión
- ✅ Guarda en BD como DECIMAL(9,6)

### ✅ Frontend (`property_model.dart`)
- ✅ Parsea correctamente `latitude` y `longitude`
- ✅ Convierte a LatLng para Flutter Map
- ✅ Tiene fallback seguro si las coordenadas son 0

---

## Verificación de Exactitud

### Para verificar que funciona correctamente:

1. **Sube una propiedad**
   - Escribe: "Calle San Vicente, 90, Sevilla"
   - Haz clic en la lupa 🔍
   - Verifica que el mapa muestra las coordenadas exactas
   - Anota las coordenadas mostradas (ej: Lat: 37.389123, Lon: -5.991456)
   - Publica el anuncio

2. **Visualiza en detalle**
   - Abre la propiedad publicada
   - Ve a "Ubicación"
   - Verifica que el mapa muestra **EXACTAMENTE** las mismas coordenadas
   - El marcador rojo debe estar en el mismo lugar exacto

3. **Verifica en BD**
   ```sql
   SELECT id, titulo, latitude, longitude FROM inmueble_anuncio ORDER BY id DESC LIMIT 1;
   ```
   - Debe mostrar los mismos valores de latitude/longitude

---

## Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| El mapa no muestra ubicación | Usuario no buscó la ubicación | Requiere búsqueda (ya implementado) |
| Coordenadas diferentes en detalle | Fallback a Sevilla (0,0 en BD) | Verificar que se guardaron en BD |
| Mapa no se muestra | latitude/longitude son 0.0 | Es normal, muestra Sevilla como fallback |
| Zoom diferente | Configuración del zoom | Ambos usan zoom: 15 ahora |

---

## Resumen

✅ **Sistema completo de ubicación exacta implementado:**
- ✅ Búsqueda de coordenadas en formulario de subida
- ✅ Vista previa con coordenadas exactas
- ✅ Validación de búsqueda
- ✅ Guardado en BD con precisión DECIMAL(9,6)
- ✅ Visualización exacta en detalle de propiedad
- ✅ Consistencia de zoom (15 en ambos lados)
- ✅ Documentación clara en el código

**Garantiza que la ubicación mostrada en el detalle es EXACTAMENTE la que se puso en el formulario de subida.** 📍
