class CrudController {
  constructor(model) {
    this.model = model;
  }

  getAll = async (req, res, next) => {
    try {
      const allElements = await this.model.findAll();
      res.json(allElements);
    } catch (error) {
      next(error);
    }
  };

  createOne = async (req, res, next) => {
    try {
      const element = await this.model.create(req.body);
      res.json(element);
    } catch (error) {
      next(error);
    }
  };

  getOne = async (req, res, next) => {
    const id = +req.params.id;
    try {
      const element = await this.model.findByPk(id);
      if (!element) {
        return res.sendStatus(404);
      }
      res.json(element);
    } catch (error) {
      next(error);
    }
  };

  updateOne = async (req, res, next) => {
    const id = +req.params.id;
    try {
      const element = await this.model.findByPk(id);
      if (!element) {
        return res.sendStatus(404);
      }
      const result = await element.update(req.body);
      res.json(result);
    } catch (error) {
      next(error);
    }
  };

  deleteOne = async (req, res, next) => {
    const id = +req.params.id;
    try {
      const deletedCount = await this.model.destroy({ where: { id } });
      res.json({ deletedCount });
    } catch (error) {
      next(error);
    }
  };
}

class CrudControllerManyToMany extends CrudController {
  constructor(model, modelAssociated) {
    const modelString = model.name;
    const modelAssociatedString = modelAssociated.name;
    // fields in association table : model_id
    const modelField = `${modelString.toLowerCase()}_id`;
    const modelAssociatedField = `${modelAssociatedString.toLowerCase()}_id`;
    super(model);

    // addModel function
    this[`add${modelAssociatedString}`] = async (req, res, next) => {
      const id = +req.params.id;
      const modelAssociatedId = req.body[modelAssociatedField];

      try {
        const modelElement = await model.findByPk(id);
        const modelAssociatedElement = await modelAssociated.findByPk(+modelAssociatedId);
        if (!modelElement || !modelAssociatedElement) {
          return res.sendStatus(404);
        }
        const result = await modelElement[`add${modelAssociatedString}`](modelAssociatedElement);
        res.json(result);
      } catch (error) {
        next(error);
      }
    };

    // removeModel Function
    this[`remove${modelAssociatedString}`] = async (req, res, next) => {
      const modelId = req.params[modelField];
      const modelAssociatedId = req.params[modelAssociatedField];

      try {
        const modelElement = await model.findByPk(+modelId);
        const modelAssociatedElement = await modelAssociated.findByPk(+modelAssociatedId);

        if (!modelElement || !modelAssociatedElement) {
          return res.sendStatus(404);
        }
        const result = await modelElement[`remove${modelAssociatedString}`](modelAssociatedElement);
        res.json(result);
      } catch (error) {
        next(error);
      }
    };
  }
}

module.exports = { CrudController, CrudControllerManyToMany };
