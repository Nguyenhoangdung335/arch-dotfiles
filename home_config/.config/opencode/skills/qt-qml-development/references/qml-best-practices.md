# QML Best Practices Reference

Qt/QML development best practices for Qt 6 and modern QML. Read this when writing QML code for QuickShell or general Qt applications.

## Table of Contents
- [Module API](#module-api)
- [Type Registration](#type-registration)
- [Concrete Types](#concrete-types)
- [Function Annotations](#function-annotations)
- [Property Lookups](#property-lookups)
- [ComponentBehavior](#componentbehavior)
- [Required Properties](#required-properties)
- [Debugging Tools](#debugging-tools)
- [Performance Optimization](#performance-optimization)
- [Common Patterns](#common-patterns)

## Module API

Qt6 uses `qt_add_qml_module` CMake API for optimal performance:

```cmake
add_executable(myapp main.cpp)

qt_add_qml_module(myapp
    URI "org.example.myapp"
    QML_FILES Main.qml
    CPP_SOURCES myplugin.cpp
)
```

Benefits:
- Automatic QML bytecode pre-compilation via qmlcachegen
- Conversion of QML code to C++ for performance
- Better tooling support

Always declare module dependencies:

```cmake
qt_add_qml_module(myapp
    URI "org.example.myapp"
    QML_FILES Main.qml
    DEPENDENCIES QtCore QtQuick
)
```

## Type Registration

Use declarative `QML_ELEMENT` macros instead of manual `qmlRegisterType`:

```cpp
// Bad - not visible to tooling
class MyThing : public QObject {
    Q_OBJECT
};

// Good - declarative and tooling-friendly
class MyThing : public QObject {
    Q_OBJECT
    QML_ELEMENT
};

// For singletons
class MySingleton : public QObject {
    Q_OBJECT
    QML_SINGLETON
};

// For uncreatable types
class MyHelper : public QObject {
    Q_OBJECT
    QML_UNCREATABLE("MyHelper is internal")
};
```

## Concrete Types

Avoid `property var` - use concrete types for better performance:

```qml
// Bad
property var size: 10
property var thing

// Good
property int size: 10
property MyThing thing
```

## Function Annotations

Always annotate function parameters for qmlcachegen optimization:

```qml
// Bad
function calculateArea(width, height) {
    return width * height;
}

// Good
function calculateArea(width: double, height: double): double {
    return width * height;
}
```

For signal handlers with parameters:

```qml
// Bad
MouseArea {
    onClicked: console.log("clicked")
}

// Good
MouseArea {
    onClicked: event => console.log("clicked at", event.x, event.y)
}
```

## Property Lookups

Use qualified property lookups instead of `parent`:

```qml
// Bad
Rectangle {
    width: parent.size  // Item has no 'size' property
}

// Good
Item {
    id: root
    property int size: 10
    
    Rectangle {
        width: root.size
    }
}
```

## ComponentBehavior

Always use `ComponentBehavior: Bound` for component ID safety:

```qml
pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root
    
    ListView {
        delegate: Rectangle {
            height: root.delegateHeight  // Safe with Bound
        }
    }
}
```

## Required Properties

Use `required property` for model data in delegates:

```qml
ListView {
    model: MyModel
    
    delegate: ItemDelegate {
        required property string title
        required property iconSource
        
        text: title
        icon.name: iconSource
    }
}
```

## Debugging Tools

### qmllint

Run static analysis on QML files:

```bash
qmllint myfile.qml
```

Add to CMake for automatic linting:

```cmake
qt_add_qml_module(myapp
    URI "org.example.myapp"
    QML_FILES myfile.qml
    LINT_EXCLUDE myfile.qml
)
```

### Qt Creator
- Set breakpoints in QML and JavaScript
- Use Debug tab for variable inspection
- QML Inspector for runtime property editing

### Visual Studio Code
Install Qt QML Extension (v1.5.0+):
- Syntax highlighting
- Code completion
- QML debugging support
- qmllint integration

### GammaRay
For deep QML scene analysis:
- Object inspection at runtime
- Binding debugging
- Signal/slot monitoring

### QML Profiler
Profile QML performance:
- Painting times
- JavaScript execution
- Binding evaluations

## Performance Optimization

### Lazy Loading

Use `LazyLoader` for deferred loading:

```qml
LazyLoader {
    source: "HeavyComponent.qml"
}
```

### Cache Frequently Used Values

```qml
Item {
    property var cachedValue
    
    onVisibleChanged: {
        if (visible) {
            cachedValue = expensiveCalculation();
        }
    }
}
```

### Avoid Repeated Binding Chains

```qml
// Bad - chain re-evaluates on every change
Text {
    text: model.data.name + " - " + model.data.value
}

// Good - use intermediate properties
Item {
    property string displayText: model.data.name + " - " + model.data.value
    
    Text {
        text: displayText
    }
}
```

## Common Patterns

### Singleton Pattern

```qml
pragma Singleton

import QtQuick

Singleton {
    id: root
    property string setting: "value"
    
    function getData() {
        return "data";
    }
}
```

### Property Aliases

```qml
Item {
    property alias text: label.text
    property alias color: label.color
    
    Text {
        id: label
    }
}
```

### Signal Connections

```qml
Item {
    Button {
        id: myButton
    }
    
    Connections {
        target: myButton
        function onClicked() {
            console.log("clicked");
        }
    }
}
```

### Model/View Separation

```qml
// Model - data only
ListModel {
    ListElement { name: "Item 1" }
    ListElement { name: "Item 2" }
}

// View - presentation only
ListView {
    model: myModel
    delegate: Text { text: model.name }
}
```
