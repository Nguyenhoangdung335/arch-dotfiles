# Qt/QML Development Instructions

## Overview

This guide covers Qt/QML development best practices for building modern, performant, and maintainable applications using Qt 6 and QML.

## Qt/QML Best Practices

### 1. Use qt_add_qml_module CMake API

Qt6 introduced a new CMake API to create QML modules. This is required for optimal performance.

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

### 2. Declarative Type Registration

Use QML_ELEMENT macros instead of manual qmlRegisterType calls:

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

### 3. Declare Module Dependencies

Always declare dependencies in qt_add_qml_module:

```cmake
qt_add_qml_module(myapp
    URI "org.example.myapp"
    QML_FILES Main.qml
    DEPENDENCIES QtCore QtQuick
)
```

### 4. Use Concrete Types

Avoid `property var` - use concrete types for better performance:

```qml
// Bad
property var size: 10
property var thing

// Good
property int size: 10
property MyThing thing
```

### 5. Annotate Function Parameters

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

### 6. Avoid Generic Property Lookups

Use qualified property lookups instead of parent:

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

### 7. Use ComponentBehavior: Bound

Always use ComponentBehavior: Bound for component ID safety:

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

### 8. Use Required Properties for Model Data

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

### 1. qmllint

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

### 2. Qt Creator

- Set breakpoints in QML and JavaScript
- Use Debug tab for variable inspection
- QML Inspector for runtime property editing

### 3. Visual Studio Code

Install Qt QML Extension (v1.5.0+):
- Syntax highlighting
- Code completion
- QML debugging support
- qmllint integration

### 4. GammaRay

For deep QML scene analysis:
- Object inspection at runtime
- Binding debugging
- Signal/slot monitoring

### 5. QML Profiler

Profile QML performance:
- Painting times
- JavaScript execution
- Binding evaluations

## Performance Optimization

### 1. Lazy Loading

Use LazyLoader for deferred loading:

```qml
LazyLoader {
    source: "HeavyComponent.qml"
}
```

### 2. Cache Frequently Used Values

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

### 3. Avoid Repeated Binding Chains

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

### 1. Singleton Pattern

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

### 2. Property Aliases

```qml
Item {
    property alias text: label.text
    property alias color: label.color
    
    Text {
        id: label
    }
}
```

### 3. Signal Connections

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

### 4. Model/View Separation

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

## Resources

- Qt Documentation: https://doc.qt.io/qt-6/
- KDAB QML Best Practices: https://www.kdab.com/10-tips-to-make-your-qml-code-faster-and-more-maintainable/
- Qt Blog - QML Debugging: https://www.qt.io/blog/qml-debugging-in-visual-studio-code
