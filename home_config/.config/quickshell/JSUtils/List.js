// @ts-check
.pragma library

/**
 * Interface for QML ListModel
 * @typedef {Object} QmlListModel
 * @property {number} count
 * @property {function(number): object} get
 */

/**
 * Finds an item in a QML ListModel.
 * 
 * @param {QmlListModel} model - The list model to search
 * @param {string} key - The property name to match
 * @param {any} value - The value to match
 * @returns {object | null} The found item or null
 */
function findInModel(model, key, value) {
    if (!model || !model.count) return null;
    
    for (var i = 0; i < model.count; i++) {
        var item = model.get(i);
        if (item[key] === value) return item;
    }
    return null;
}
