interface ButtonProps {
    type: "primary" | "success" | "warning";
    size: "md" | "sm" | "lg";
    children: React.ReactNode;
}

const Button: React.FC<ButtonProps> = (props) => {
    return <button>{props.children}</button>
}

export default Button;
