# Block RAM

- For the XC3S200:
  - 2 RAM columns
  - 6 RAM blocks per column
  - 12 Total RAM blocks
  - 221,184 Total RAM Bits
  - 216K Total RAM Kbits
- Each block RAM contains 18,432 bits
- Two ports, A and B
  - Both support read and write
  - Each port is synchronous with its own clock
  - Reads are synchronous

| Signal Description                        | Single Port   | Dual Port     | Direction |
|-------------------------------------------|---------------|---------------|-----------|
| Data Input Bus                            | DI            | DIA, DIB      | Input     |
| Parity Data Input Bus                     | DIP           | DIPA, DIPB    | Input     |
| Data Output Bus                           | DO            | DOA, DOB      | Output    |
| Parity Data Output                        | DOP           | DOPA, DOPB    | Output    |
| Address Bus                               | ADDR          | ADDRA, ADDRB  | Input     |
| Write Enable                              | WE            | WEA, WEB      | Input     |
| Clock Enable                              | EN            | ENA, ENB      | Input     |
| Synchronous Set/Reset                     | SSR           | SSRA, SSRB    | Input     |
| Clock                                     | CLK           | CLKA, CLKB    | Input     |
