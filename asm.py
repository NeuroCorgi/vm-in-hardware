import struct

class SynacorAssembler:
    OPCODES = {
        'halt': 0, 'set': 1, 'push': 2, 'pop': 3,
        'eq': 4, 'gt': 5, 'jmp': 6, 'jt': 7, 'jf': 8,
        'add': 9, 'mult': 10, 'mod': 11, 'and': 12, 'or': 13,
        'not': 14, 'rmem': 15, 'wmem': 16, 'call': 17,
        'ret': 18, 'out': 19, 'in': 20, 'noop': 21, 'sub': 22,
    }

    def __init__(self, source_file, output_file):
        self.source_file = source_file
        self.output_file = output_file
        self.labels = {}
        self.binary = []

    def parse_operand(self, operand):
        if operand.lstrip('-').isdigit():
            value = int(operand)
            if -32768 <= value < 0:  # Support for negative numbers
                return 32768 + value
            elif 0 <= value <= 32767:
                return value
        elif operand.startswith('r') and operand[1:].isdigit():
            reg = int(operand[1:])
            if 0 <= reg <= 8:
                return 32768 + reg
        elif operand in self.labels:
            return self.labels[operand]
        raise ValueError(f"Invalid operand: {operand}")

    def first_pass(self, lines):
        address = 0
        for line in lines:
            line = line.split(';')[0].strip()  # Remove comments
            if not line:
                continue
            parts = line.split()
            if parts[0].startswith(':'):
                label = parts[0][1:]
                self.labels[label] = address
            else:
                address += 1 + len(parts[1:])

    def assemble(self):
        with open(self.source_file, 'r') as f:
            lines = f.readlines()

        # First pass to collect labels
        self.first_pass(lines)

        # Second pass to generate binary
        for line in lines:
            line = line.split(';')[0].strip()  # Remove comments
            if not line or line.startswith(':'):
                continue

            parts = line.split()
            instr = parts[0]
            if instr not in self.OPCODES:
                raise ValueError(f"Unknown instruction: {instr}")

            self.binary.append(self.OPCODES[instr])
            operands = parts[1:]
            for operand in operands:
                self.binary.append(self.parse_operand(operand))

        # Write binary file
        with open(self.output_file, 'wb') as f:
            for value in self.binary:
                f.write(struct.pack('<H', value))

        print(f"Assembled binary written to {self.output_file}")


# Example usage
source_file = 'fib.asm'  # Replace with your source file
output_file = 'fib.bin'  # Replace with your output binary file
assembler = SynacorAssembler(source_file, output_file)
assembler.assemble()
