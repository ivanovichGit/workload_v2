# Workload – Sistema de Predicción de Carga de Trabajo

Este proyecto presenta un sistema de predicción de carga de trabajo (workload) para empleados, basado en distintos atributos laborales.  
La idea principal es ofrecer una herramienta clara, accesible y fácil de usar, tanto para entender el modelo como para probar predicciones de manera práctica.

El sistema está compuesto por tres partes principales:
- Un notebook de referencia donde se construye y analiza el modelo
- Un documento que explica el fundamento teórico y metodológico
- Una aplicación web interactiva para realizar predicciones

---

## Notebook de referencia

El notebook es el punto de partida del sistema.  
Aquí se puede ver todo el proceso de principio a fin: preparación de los datos, entrenamiento del modelo, evaluación y pruebas de predicción.

Puedes acceder directamente al notebook en el siguiente enlace:

https://colab.research.google.com/drive/1MAzcOfBp9f9jXAmHjg8dkZVCuth_iH8k

Este notebook está pensado como material de apoyo para comprender cómo funciona el sistema internamente y qué decisiones se tomaron durante su desarrollo.

---

## Fundamento y documentación del sistema

El contexto del problema, la explicación de las variables utilizadas y el fundamento del sistema se encuentran documentados en el siguiente archivo:

https://docs.google.com/document/d/1P3JHQxHM2b1CSVKK12xP3gwYpF5BnFQ2vrVZi0Sw9lU/edit?tab=t.0#heading=h.ukz2c85uzrq2

Este documento explica:
- El objetivo del sistema
- La lógica detrás de la selección de atributos
- El enfoque utilizado para modelar la carga de trabajo
- La interpretación general de los resultados

Es recomendable revisarlo antes o después del notebook para tener una visión más completa del proyecto.

---

## Aplicación web

Además del notebook, el sistema cuenta con una aplicación web que permite realizar predicciones de forma sencilla, sin necesidad de programar.

La aplicación se encuentra disponible en:

https://ivanovichgit.github.io/workload_web/

Al abrir el enlace, se mostrará la interfaz de la aplicación tal como se aprecia en la imagen del proyecto.

---

## Cómo usar la aplicación

El uso de la aplicación es muy simple:

1. Abre el enlace de la aplicación web
2. Asigna valores a los distintos atributos solicitados
3. Una vez completados los campos, haz clic en el botón "Predecir"
4. El sistema mostrará el resultado de la predicción de carga de trabajo

---

## Atributos utilizados para la predicción

La predicción se realiza a partir de los siguientes atributos:

- Departamento
- Nivel de rol
- Salario mensual
- Horas semanales promedio
- Proyectos asignados
- Evaluaciones de desempeño
- Días de ausencia
- Satisfacción laboral

Cada uno de estos valores influye en la estimación final de la carga de trabajo.

---

## Objetivo del proyecto

El objetivo de este sistema es mostrar cómo un modelo de aprendizaje automático puede apoyar el análisis de carga laboral y servir como herramienta de apoyo para la toma de decisiones.

El proyecto busca ser claro, didáctico y fácil de explorar, tanto desde el punto de vista técnico como desde el uso práctico.

---

## Notas finales

Este repositorio puede utilizarse como base para:
- Análisis académicos
- Proyectos de aprendizaje automático
- Prototipos de sistemas de apoyo a recursos humanos

El modelo y la aplicación pueden extenderse o ajustarse según nuevas necesidades o datos adicionales.
