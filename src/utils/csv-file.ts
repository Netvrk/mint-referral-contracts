import { FormatterOptionsArgs, Row, writeToStream } from "@fast-csv/format";
import { parseStream } from "fast-csv";

import * as fs from "fs";

type CsvFileOpts = {
  headers: string[];
  path: string;
};

export class CsvFile {
  static write(stream: NodeJS.WritableStream, rows: Row[], options: FormatterOptionsArgs<Row, Row>): Promise<void> {
    return new Promise((res, rej) => {
      writeToStream(stream, rows, options)
        .on("error", (err: Error) => rej(err))
        .on("finish", () => res());
    });
  }

  private firstTime = true;

  private readonly headers: string[];

  private readonly path: string;

  private readonly writeOpts: FormatterOptionsArgs<Row, Row>;

  constructor(opts: CsvFileOpts) {
    this.headers = opts.headers;
    this.path = opts.path;
    this.writeOpts = { headers: this.headers, includeEndRowDelimiter: true };
  }

  add(rows: Row[]): Promise<void> {
    return CsvFile.write(
      this.firstTime ? fs.createWriteStream(this.path) : fs.createWriteStream(this.path, { flags: "a" }),

      rows,
      {
        ...this.writeOpts,
        writeHeaders: this.firstTime,
      } as FormatterOptionsArgs<Row, Row>
    ).then(() => {
      if (this.firstTime) this.firstTime = false;
    });
  }

  read(): any {
    const pr = new Promise((resolve, reject) => {
      const csvDataArray: any = [];
      const stream = fs.createReadStream(this.path);

      parseStream(stream, { headers: this.headers })
        .on("data", (data) => {
          csvDataArray.push(data);
        })
        .on("end", async () => {
          try {
            return resolve(csvDataArray.slice(1));
          } catch (error) {
            reject(error);
          }
        });
    });
    return pr;
  }
}
