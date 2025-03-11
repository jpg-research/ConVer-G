package fr.cnrs.liris.jpugetgil.converg.sql;

import org.apache.jena.sparql.algebra.op.OpSlice;

public class SQLQuery {

    private String sql;

    private SQLContext context;

    private OpSlice opSlice;

    public SQLQuery(String sql, SQLContext context) {
        this.sql = sql;
        this.context = context;
    }

    public String getSql() {
        return sql;
    }

    public void setSql(String sql) {
        this.sql = sql;
    }

    public OpSlice getOpSlice() {
        return opSlice;
    }

    public void setOpSlice(OpSlice opSlice) {
        this.opSlice = opSlice;
    }

    public SQLContext getContext() {
        return context;
    }

    public void setContext(SQLContext context) {
        this.context = context;
    }
}
