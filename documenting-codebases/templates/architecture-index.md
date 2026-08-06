# Architecture Documentation

This directory contains the architecture documentation for **## TODO: Project Name ##**,
generated using the [C4 model](https://c4model.com/) and BPMN process diagrams.

## C4 Architecture Diagrams

The C4 model provides 4 levels of abstraction. This documentation covers levels 1-3
(Context, Container, Component). Level 4 (Code) is intentionally omitted as it changes
frequently and is visible in the source code.

### Level 1: System Context

Shows the system as a whole and its relationships with users and external systems.

- [System Context Diagram](system-context.puml)

### Level 2: Container

Shows the high-level technical architecture: deployable units, databases, queues,
and their interactions.

- [Container Diagram](container.puml)

### Level 3: Component

Shows the internal structure of each container: modules, packages, classes,
and their dependencies.

- [Component Diagram - ## TODO: Container 1 ##](component-## TODO: container1 ##.puml)
- [Component Diagram - ## TODO: Container 2 ##](component-## TODO: container2 ##.puml)

## BPMN Process Diagrams

Key business processes documented as PlantUML activity diagrams (BPMN-style).

- [## TODO: Process 1 ##](bpmn-## TODO: process1 ##.puml)
- [## TODO: Process 2 ##](bpmn-## TODO: process2 ##.puml)
- [## TODO: Process 3 ##](bpmn-## TODO: process3 ##.puml)

## Rendering

These `.puml` files use [PlantUML](https://plantuml.com/) syntax with the
[C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML) standard library.

To render:
- **VS Code**: Install the PlantUML extension, open `.puml` file, press `Alt+D`
- **CLI**: `java -jar plantuml.jar docs/architecture/*.puml`
- **Online**: Paste content at https://www.plantuml.com/plantuml/uml/

## Tech Stack

- **Language**: ## TODO: language + version ##
- **Build**: ## TODO: build tool ##
- **Framework**: ## TODO: framework + version ##
- **Modules**: ## TODO: list of modules ##
- **External systems**: ## TODO: list of external deps ##