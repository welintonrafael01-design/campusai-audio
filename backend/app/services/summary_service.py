def generate_basic_summary(text: str, max_length: int = 1200):
    clean_text = " ".join(text.split())

    if len(clean_text) <= max_length:
        return clean_text

    return clean_text[:max_length] + "..."