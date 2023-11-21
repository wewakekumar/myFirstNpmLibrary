const makeButton = (container, attributes, children) => {
    const button = container.createElement("button");

    Object.entries(attributes).forEach(([attrName, attrValue]) => {
        button.setAttribute(attrName, attrValue);
    })

    button.innerHTML = children;

    return button;
}

export default makeButton;