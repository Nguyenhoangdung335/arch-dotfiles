pub fn update_if_changed<T: PartialEq>(field: &mut T, new_value: T) -> bool {
    if field != &new_value {
        *field = new_value;
        true
    } else {
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_update_if_changed_same_value_returns_false() {
        let mut value = 42;
        let result = update_if_changed(&mut value, 42);
        assert!(!result);
        assert_eq!(value, 42);
    }

    #[test]
    fn test_update_if_changed_different_value_returns_true() {
        let mut value = 42;
        let result = update_if_changed(&mut value, 100);
        assert!(result);
        assert_eq!(value, 100);
    }

    #[test]
    fn test_update_if_changed_string() {
        let mut value = String::from("hello");
        let result = update_if_changed(&mut value, String::from("world"));
        assert!(result);
        assert_eq!(value, "world");
    }

    #[test]
    fn test_update_if_changed_string_same() {
        let mut value = String::from("hello");
        let result = update_if_changed(&mut value, String::from("hello"));
        assert!(!result);
        assert_eq!(value, "hello");
    }

    #[test]
    fn test_update_if_changed_bool() {
        let mut value = false;
        let result = update_if_changed(&mut value, true);
        assert!(result);
        assert_eq!(value, true);
    }

    #[test]
    fn test_update_if_changed_option() {
        let mut value: Option<String> = Some(String::from("old"));
        let result = update_if_changed(&mut value, Some(String::from("new")));
        assert!(result);
        assert_eq!(value, Some(String::from("new")));
    }

    #[test]
    fn test_update_if_changed_option_none_to_some() {
        let mut value: Option<String> = None;
        let result = update_if_changed(&mut value, Some(String::from("new")));
        assert!(result);
        assert_eq!(value, Some(String::from("new")));
    }

    #[test]
    fn test_update_if_changed_vec() {
        let mut value = vec![1, 2, 3];
        let result = update_if_changed(&mut value, vec![4, 5, 6]);
        assert!(result);
        assert_eq!(value, vec![4, 5, 6]);
    }
}
