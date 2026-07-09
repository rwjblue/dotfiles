use tree_sitter::Node;

/// Get the line number from a byte offset using precomputed line offsets.
pub fn get_line_number(line_offsets: &[(usize, &str)], byte_offset: usize) -> usize {
    match line_offsets.binary_search_by(|&(offset, _)| offset.cmp(&byte_offset)) {
        Ok(index) => index,
        Err(index) => index,
    }
}

/// Extract the full line of source that `node` spans.
pub fn get_line_content<'a>(source_code: &'a str, node: Node) -> &'a str {
    let start = source_code[..node.start_byte()]
        .rfind('\n')
        .map(|pos| pos + 1)
        .unwrap_or(0);
    let end = source_code[node.end_byte()..]
        .find('\n')
        .map(|pos| node.end_byte() + pos)
        .unwrap_or(source_code.len());

    &source_code[start..end]
}

#[cfg(test)]
mod tests {
    use super::{get_line_content, get_line_number};
    use tree_sitter::Parser;
    use tree_sitter_bash as bash;

    #[test]
    fn test_get_line_number() {
        let source = "echo first\nsecond line\nthird line\n";
        let line_offsets: Vec<_> = source.match_indices('\n').collect();

        assert_eq!(get_line_number(&line_offsets, 0), 0);

        let second_line_offset = source.find("second").unwrap();
        assert_eq!(get_line_number(&line_offsets, second_line_offset), 1);

        let third_line_offset = source.find("third").unwrap();
        assert_eq!(get_line_number(&line_offsets, third_line_offset), 2);
    }

    #[test]
    fn test_get_line_content() {
        let source = "echo first\nsecond line\nthird line\n";
        let mut parser = Parser::new();
        parser.set_language(&bash::LANGUAGE.into()).unwrap();
        let tree = parser.parse(source, None).unwrap();

        let first_cmd = tree.root_node().named_child(0).unwrap();
        assert_eq!(get_line_content(source, first_cmd), "echo first");

        let second_cmd = tree.root_node().named_child(1).unwrap();
        assert_eq!(get_line_content(source, second_cmd), "second line");
    }
}
