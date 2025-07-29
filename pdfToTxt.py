from pdfminer.high_level import extract_text

# Replace with your actual file path
pdf_path = "Student Handbook 2024-25.pdf"
text = extract_text(pdf_path)

# Save to text file
with open("output.txt", "w", encoding="utf-8") as f:
    f.write(text)

print("PDF converted to text successfully.")
