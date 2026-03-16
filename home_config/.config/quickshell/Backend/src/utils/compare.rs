pub fn update_if_changed<T: PartialEq>(field: &mut T, new_value: T) -> bool {
    if field != &new_value {
        *field = new_value;
        true
    } else {
        false
    }
}
